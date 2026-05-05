"""
dynamodb_ops.py — Lambda handlers for the DynamoDB MCP API.

This module consolidates all DynamoDB operation tools into a single Python file.
Each tool is a top-level handler wired to its own Lambda function and IAM role
via Terraform, while sharing the boto3 DynamoDB client and helper functions.

Handler → Lambda function → API Gateway route mapping:
    get_item_handler         →  dynamodb-get-item        →  POST /dynamodb/get-item
    put_item_handler         →  dynamodb-put-item        →  POST /dynamodb/put-item
    update_item_handler      →  dynamodb-update-item     →  POST /dynamodb/update-item
    delete_item_handler      →  dynamodb-delete-item     →  POST /dynamodb/delete-item
    query_handler            →  dynamodb-query           →  POST /dynamodb/query
    scan_handler             →  dynamodb-scan            →  POST /dynamodb/scan
    batch_get_handler        →  dynamodb-batch-get       →  POST /dynamodb/batch-get
    list_tables_handler      →  dynamodb-list-tables     →  POST /dynamodb/list-tables
    describe_table_handler   →  dynamodb-describe-table  →  POST /dynamodb/describe-table
    count_items_handler      →  dynamodb-count-items     →  POST /dynamodb/count-items

Response format:
    All handlers return plain-text summaries in the response body rather than
    raw DynamoDB JSON. This lets the AI narrate results naturally without
    parsing nested attribute structures.

Authentication:
    All API Gateway routes require AWS_IAM authorization. Callers must sign
    requests with SigV4 using credentials that have appropriate DynamoDB
    permissions (dynamodb:GetItem, dynamodb:PutItem, etc.).
"""

import json
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# ---------------------------------------------------------------------------
# Module-level singletons
# ---------------------------------------------------------------------------

dynamodb = boto3.client("dynamodb")
dynamodb_resource = boto3.resource("dynamodb")


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _audit_log(event: dict, tool: str) -> None:
    """Log the tool invocation with the calling user for audit purposes.

    Args:
        event (dict): API Gateway v2 HTTP event.
        tool (str): Name of the MCP tool being invoked.
    """
    user = (event.get("headers") or {}).get("x-mcp-user", "unknown")
    print(f"AUDIT tool={tool} user={user}")


def _response(status_code: int, text: str) -> dict:
    """Build an API Gateway v2 HTTP response with a plain-text body.

    Args:
        status_code (int): HTTP status code to return.
        text (str): Plain-text response body for AI narration.

    Returns:
        dict: Response dict with statusCode, headers, and body.
    """
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "text/plain"},
        "body": text,
    }


def _parse_json_body(event: dict) -> dict:
    """Parse JSON body from API Gateway event.

    Args:
        event (dict): API Gateway v2 HTTP event.

    Returns:
        dict: Parsed JSON body or empty dict if parsing fails.
    """
    try:
        body = event.get("body", "{}")
        if isinstance(body, str):
            return json.loads(body) if body else {}
        return body
    except json.JSONDecodeError:
        return {}


def _format_item(item: dict) -> str:
    """Format a DynamoDB item for human-readable display.

    Args:
        item (dict): DynamoDB item in AWS format.

    Returns:
        str: Formatted item representation.
    """
    if not item:
        return "  (empty item)"

    lines = []
    for key, value in item.items():
        # Extract actual value from DynamoDB type wrapper
        if isinstance(value, dict):
            if 'S' in value:
                lines.append(f"  {key}: {value['S']}")
            elif 'N' in value:
                lines.append(f"  {key}: {value['N']}")
            elif 'BOOL' in value:
                lines.append(f"  {key}: {value['BOOL']}")
            elif 'M' in value:
                lines.append(f"  {key}: {json.dumps(value['M'], indent=2)}")
            elif 'L' in value:
                lines.append(f"  {key}: {json.dumps(value['L'], indent=2)}")
            elif 'NULL' in value:
                lines.append(f"  {key}: null")
            else:
                lines.append(f"  {key}: {json.dumps(value)}")
        else:
            lines.append(f"  {key}: {value}")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tool registry
# ---------------------------------------------------------------------------

TOOL_REGISTRY = [
    {
        "name": "dynamodb_get_item",
        "description": "Retrieve a single item from DynamoDB table by primary key. Requires table_name and key parameters.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "key": {"type": "object", "description": "Primary key as JSON object (e.g., {\"id\": \"123\"})"}
            },
            "required": ["table_name", "key"]
        },
        "route": "/dynamodb/get-item",
    },
    {
        "name": "dynamodb_put_item",
        "description": "Add or replace an item in DynamoDB table. Requires table_name and item parameters.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "item": {"type": "object", "description": "Item to put as JSON object"}
            },
            "required": ["table_name", "item"]
        },
        "route": "/dynamodb/put-item",
    },
    {
        "name": "dynamodb_update_item",
        "description": "Update specific attributes of an item in DynamoDB. Requires table_name, key, and update_expression.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "key": {"type": "object", "description": "Primary key as JSON object"},
                "update_expression": {"type": "string", "description": "Update expression (e.g., 'SET #name = :val')"},
                "expression_attribute_names": {"type": "object", "description": "Attribute name mappings"},
                "expression_attribute_values": {"type": "object", "description": "Attribute value mappings"}
            },
            "required": ["table_name", "key", "update_expression"]
        },
        "route": "/dynamodb/update-item",
    },
    {
        "name": "dynamodb_delete_item",
        "description": "Delete an item from DynamoDB table by primary key. Requires table_name and key parameters.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "key": {"type": "object", "description": "Primary key as JSON object"}
            },
            "required": ["table_name", "key"]
        },
        "route": "/dynamodb/delete-item",
    },
    {
        "name": "dynamodb_query",
        "description": "Query items from DynamoDB using partition key and optional filters. Requires table_name and key_condition_expression.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "key_condition_expression": {"type": "string", "description": "Key condition expression"},
                "expression_attribute_names": {"type": "object", "description": "Attribute name mappings"},
                "expression_attribute_values": {"type": "object", "description": "Attribute value mappings"},
                "filter_expression": {"type": "string", "description": "Optional filter expression"},
                "limit": {"type": "integer", "description": "Maximum number of items to return"}
            },
            "required": ["table_name", "key_condition_expression"]
        },
        "route": "/dynamodb/query",
    },
    {
        "name": "dynamodb_scan",
        "description": "Scan DynamoDB table with optional filters. Returns all items or filtered subset. Requires table_name.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "filter_expression": {"type": "string", "description": "Optional filter expression"},
                "expression_attribute_names": {"type": "object", "description": "Attribute name mappings"},
                "expression_attribute_values": {"type": "object", "description": "Attribute value mappings"},
                "limit": {"type": "integer", "description": "Maximum number of items to return"}
            },
            "required": ["table_name"]
        },
        "route": "/dynamodb/scan",
    },
    {
        "name": "dynamodb_batch_get",
        "description": "Retrieve multiple items from DynamoDB in a single request. Requires table_name and keys array.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"},
                "keys": {"type": "array", "description": "Array of primary keys to retrieve"}
            },
            "required": ["table_name", "keys"]
        },
        "route": "/dynamodb/batch-get",
    },
    {
        "name": "dynamodb_list_tables",
        "description": "List all DynamoDB tables in the AWS account/region.",
        "inputSchema": {"type": "object", "properties": {}},
        "route": "/dynamodb/list-tables",
    },
    {
        "name": "dynamodb_describe_table",
        "description": "Get detailed metadata about a DynamoDB table including schema, keys, and statistics. Requires table_name.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"}
            },
            "required": ["table_name"]
        },
        "route": "/dynamodb/describe-table",
    },
    {
        "name": "dynamodb_count_items",
        "description": "Get total item count in a DynamoDB table. Requires table_name.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "table_name": {"type": "string", "description": "DynamoDB table name"}
            },
            "required": ["table_name"]
        },
        "route": "/dynamodb/count-items",
    },
]


# ---------------------------------------------------------------------------
# MCP tool handlers
# ---------------------------------------------------------------------------

def get_item_handler(event, context):
    """Retrieve a single item from DynamoDB by primary key."""
    _audit_log(event, "dynamodb_get_item")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    key = params.get("key")

    if not table_name or not key:
        return _response(400, "Missing required parameters: table_name and key")

    try:
        # Convert simple key format to DynamoDB format
        dynamodb_key = {}
        for k, v in key.items():
            if isinstance(v, str):
                dynamodb_key[k] = {"S": v}
            elif isinstance(v, (int, float)):
                dynamodb_key[k] = {"N": str(v)}
            elif isinstance(v, bool):
                dynamodb_key[k] = {"BOOL": v}

        response = dynamodb.get_item(
            TableName=table_name,
            Key=dynamodb_key
        )

        if "Item" not in response:
            return _response(404, f"Item not found in table '{table_name}' with key: {json.dumps(key)}")

        item_str = _format_item(response["Item"])
        return _response(200, f"Item from table '{table_name}':\n{item_str}")

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def put_item_handler(event, context):
    """Add or replace an item in DynamoDB."""
    _audit_log(event, "dynamodb_put_item")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    item = params.get("item")

    if not table_name or not item:
        return _response(400, "Missing required parameters: table_name and item")

    try:
        # Convert simple format to DynamoDB format
        dynamodb_item = {}
        for k, v in item.items():
            if isinstance(v, str):
                dynamodb_item[k] = {"S": v}
            elif isinstance(v, bool):
                dynamodb_item[k] = {"BOOL": v}
            elif isinstance(v, (int, float)):
                dynamodb_item[k] = {"N": str(v)}
            elif isinstance(v, dict):
                dynamodb_item[k] = {"M": v}
            elif isinstance(v, list):
                dynamodb_item[k] = {"L": v}
            elif v is None:
                dynamodb_item[k] = {"NULL": True}

        dynamodb.put_item(
            TableName=table_name,
            Item=dynamodb_item
        )

        return _response(200, f"Successfully added/updated item in table '{table_name}'")

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def update_item_handler(event, context):
    """Update specific attributes of an item in DynamoDB."""
    _audit_log(event, "dynamodb_update_item")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    key = params.get("key")
    update_expression = params.get("update_expression")

    if not table_name or not key or not update_expression:
        return _response(400, "Missing required parameters: table_name, key, and update_expression")

    try:
        # Convert key to DynamoDB format
        dynamodb_key = {}
        for k, v in key.items():
            if isinstance(v, str):
                dynamodb_key[k] = {"S": v}
            elif isinstance(v, (int, float)):
                dynamodb_key[k] = {"N": str(v)}

        update_params = {
            "TableName": table_name,
            "Key": dynamodb_key,
            "UpdateExpression": update_expression,
            "ReturnValues": "ALL_NEW"
        }

        if params.get("expression_attribute_names"):
            update_params["ExpressionAttributeNames"] = params["expression_attribute_names"]

        if params.get("expression_attribute_values"):
            # Convert values to DynamoDB format
            attr_values = {}
            for k, v in params["expression_attribute_values"].items():
                if isinstance(v, str):
                    attr_values[k] = {"S": v}
                elif isinstance(v, (int, float)):
                    attr_values[k] = {"N": str(v)}
                elif isinstance(v, bool):
                    attr_values[k] = {"BOOL": v}
            update_params["ExpressionAttributeValues"] = attr_values

        response = dynamodb.update_item(**update_params)

        item_str = _format_item(response.get("Attributes", {}))
        return _response(200, f"Successfully updated item in table '{table_name}':\n{item_str}")

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def delete_item_handler(event, context):
    """Delete an item from DynamoDB by primary key."""
    _audit_log(event, "dynamodb_delete_item")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    key = params.get("key")

    if not table_name or not key:
        return _response(400, "Missing required parameters: table_name and key")

    try:
        # Convert key to DynamoDB format
        dynamodb_key = {}
        for k, v in key.items():
            if isinstance(v, str):
                dynamodb_key[k] = {"S": v}
            elif isinstance(v, (int, float)):
                dynamodb_key[k] = {"N": str(v)}

        dynamodb.delete_item(
            TableName=table_name,
            Key=dynamodb_key
        )

        return _response(200, f"Successfully deleted item from table '{table_name}' with key: {json.dumps(key)}")

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def query_handler(event, context):
    """Query items from DynamoDB using partition key and optional filters."""
    _audit_log(event, "dynamodb_query")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    key_condition_expression = params.get("key_condition_expression")

    if not table_name or not key_condition_expression:
        return _response(400, "Missing required parameters: table_name and key_condition_expression")

    try:
        query_params = {
            "TableName": table_name,
            "KeyConditionExpression": key_condition_expression
        }

        if params.get("expression_attribute_names"):
            query_params["ExpressionAttributeNames"] = params["expression_attribute_names"]

        if params.get("expression_attribute_values"):
            # Convert values to DynamoDB format
            attr_values = {}
            for k, v in params["expression_attribute_values"].items():
                if isinstance(v, str):
                    attr_values[k] = {"S": v}
                elif isinstance(v, (int, float)):
                    attr_values[k] = {"N": str(v)}
                elif isinstance(v, bool):
                    attr_values[k] = {"BOOL": v}
            query_params["ExpressionAttributeValues"] = attr_values

        if params.get("filter_expression"):
            query_params["FilterExpression"] = params["filter_expression"]

        if params.get("limit"):
            query_params["Limit"] = params["limit"]

        response = dynamodb.query(**query_params)

        items = response.get("Items", [])
        count = len(items)

        if count == 0:
            return _response(200, f"No items found in table '{table_name}' matching the query")

        lines = [f"Query results from table '{table_name}' ({count} items):"]
        for idx, item in enumerate(items[:10], 1):  # Limit display to first 10
            lines.append(f"\nItem {idx}:")
            lines.append(_format_item(item))

        if count > 10:
            lines.append(f"\n... and {count - 10} more items")

        return _response(200, "\n".join(lines))

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def scan_handler(event, context):
    """Scan DynamoDB table with optional filters."""
    _audit_log(event, "dynamodb_scan")
    params = _parse_json_body(event)

    table_name = params.get("table_name")

    if not table_name:
        return _response(400, "Missing required parameter: table_name")

    try:
        scan_params = {
            "TableName": table_name
        }

        if params.get("filter_expression"):
            scan_params["FilterExpression"] = params["filter_expression"]

        if params.get("expression_attribute_names"):
            scan_params["ExpressionAttributeNames"] = params["expression_attribute_names"]

        if params.get("expression_attribute_values"):
            # Convert values to DynamoDB format
            attr_values = {}
            for k, v in params["expression_attribute_values"].items():
                if isinstance(v, str):
                    attr_values[k] = {"S": v}
                elif isinstance(v, (int, float)):
                    attr_values[k] = {"N": str(v)}
                elif isinstance(v, bool):
                    attr_values[k] = {"BOOL": v}
            scan_params["ExpressionAttributeValues"] = attr_values

        if params.get("limit"):
            scan_params["Limit"] = params["limit"]

        response = dynamodb.scan(**scan_params)

        items = response.get("Items", [])
        count = len(items)

        if count == 0:
            return _response(200, f"No items found in table '{table_name}'")

        lines = [f"Scan results from table '{table_name}' ({count} items):"]
        for idx, item in enumerate(items[:10], 1):  # Limit display to first 10
            lines.append(f"\nItem {idx}:")
            lines.append(_format_item(item))

        if count > 10:
            lines.append(f"\n... and {count - 10} more items")

        return _response(200, "\n".join(lines))

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def batch_get_handler(event, context):
    """Retrieve multiple items from DynamoDB in a single request."""
    _audit_log(event, "dynamodb_batch_get")
    params = _parse_json_body(event)

    table_name = params.get("table_name")
    keys = params.get("keys")

    if not table_name or not keys:
        return _response(400, "Missing required parameters: table_name and keys")

    try:
        # Convert keys to DynamoDB format
        dynamodb_keys = []
        for key in keys:
            dynamodb_key = {}
            for k, v in key.items():
                if isinstance(v, str):
                    dynamodb_key[k] = {"S": v}
                elif isinstance(v, (int, float)):
                    dynamodb_key[k] = {"N": str(v)}
            dynamodb_keys.append(dynamodb_key)

        response = dynamodb.batch_get_item(
            RequestItems={
                table_name: {
                    "Keys": dynamodb_keys
                }
            }
        )

        items = response.get("Responses", {}).get(table_name, [])
        count = len(items)

        if count == 0:
            return _response(200, f"No items found in table '{table_name}' for the provided keys")

        lines = [f"Batch get results from table '{table_name}' ({count} items):"]
        for idx, item in enumerate(items, 1):
            lines.append(f"\nItem {idx}:")
            lines.append(_format_item(item))

        return _response(200, "\n".join(lines))

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def list_tables_handler(event, context):
    """List all DynamoDB tables in the AWS account/region."""
    _audit_log(event, "dynamodb_list_tables")

    try:
        response = dynamodb.list_tables()
        tables = response.get("TableNames", [])

        if not tables:
            return _response(200, "No DynamoDB tables found in this region")

        lines = [f"DynamoDB tables in region ({len(tables)} total):"]
        for table in tables:
            lines.append(f"  - {table}")

        return _response(200, "\n".join(lines))

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def describe_table_handler(event, context):
    """Get detailed metadata about a DynamoDB table."""
    _audit_log(event, "dynamodb_describe_table")
    params = _parse_json_body(event)

    table_name = params.get("table_name")

    if not table_name:
        return _response(400, "Missing required parameter: table_name")

    try:
        response = dynamodb.describe_table(TableName=table_name)
        table = response.get("Table", {})

        lines = [f"Table: {table_name}"]
        lines.append(f"Status: {table.get('TableStatus')}")
        lines.append(f"Item count: {table.get('ItemCount', 0):,}")
        lines.append(f"Table size: {table.get('TableSizeBytes', 0):,} bytes")
        lines.append(f"Creation time: {table.get('CreationDateTime')}")

        # Key schema
        lines.append("\nKey Schema:")
        for key in table.get("KeySchema", []):
            lines.append(f"  {key['AttributeName']} ({key['KeyType']})")

        # Attribute definitions
        lines.append("\nAttribute Definitions:")
        for attr in table.get("AttributeDefinitions", []):
            lines.append(f"  {attr['AttributeName']}: {attr['AttributeType']}")

        # GSIs
        gsis = table.get("GlobalSecondaryIndexes", [])
        if gsis:
            lines.append("\nGlobal Secondary Indexes:")
            for gsi in gsis:
                lines.append(f"  - {gsi['IndexName']}")

        # LSIs
        lsis = table.get("LocalSecondaryIndexes", [])
        if lsis:
            lines.append("\nLocal Secondary Indexes:")
            for lsi in lsis:
                lines.append(f"  - {lsi['IndexName']}")

        return _response(200, "\n".join(lines))

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def count_items_handler(event, context):
    """Get total item count in a DynamoDB table."""
    _audit_log(event, "dynamodb_count_items")
    params = _parse_json_body(event)

    table_name = params.get("table_name")

    if not table_name:
        return _response(400, "Missing required parameter: table_name")

    try:
        # Use describe_table for quick count (updated every 6 hours)
        response = dynamodb.describe_table(TableName=table_name)
        count = response.get("Table", {}).get("ItemCount", 0)

        return _response(200, f"Table '{table_name}' contains approximately {count:,} items (updated every ~6 hours)")

    except ClientError as exc:
        msg = exc.response["Error"]["Message"]
        return _response(500, f"DynamoDB error: {msg}")


def tools_handler(event, context):
    """Return the MCP tool registry for proxy self-configuration."""
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(TOOL_REGISTRY),
    }
