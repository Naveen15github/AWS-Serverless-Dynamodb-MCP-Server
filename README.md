# AWS Serverless MCP: DynamoDB API

A serverless MCP (Model Context Protocol) backend on AWS that enables AI assistants to interact with DynamoDB tables conversationally. The architecture combines Lambda functions, API Gateway, and IAM security with a local proxy for transparent MCP communication. Read more here: https://dev.to/aws-builders/building-a-serverless-dynamodb-mcp-making-your-ai-talk-to-your-database-3jne

## Overview

This project implements a comprehensive DynamoDB operations API that exposes 10 different tools for interacting with DynamoDB tables through Claude Desktop or any MCP-compatible client.

## Features

- **10 DynamoDB Operations**: GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, ListTables, DescribeTable, CountItems
- **Serverless Architecture**: All operations run on AWS Lambda
- **Secure by Default**: AWS IAM authorization with SigV4 request signing
- **Self-Configuring Proxy**: Dynamic tool discovery from the backend
- **Plain-Text Responses**: Human-readable output optimized for AI assistants

## Architecture

```
Claude Desktop (MCP client)
     │  stdio / JSON-RPC
     ▼
proxy.sh — holds IAM credentials, signs with SigV4
     │  HTTPS + AWS_IAM auth
     ▼
API Gateway (HTTP API v2) — dynamodb-api
     │  routes by method + path
     ├── GET  /tools                   → Lambda: dynamodb-tools
     ├── POST /dynamodb/get-item       → Lambda: dynamodb-get-item
     ├── POST /dynamodb/put-item       → Lambda: dynamodb-put-item
     ├── POST /dynamodb/update-item    → Lambda: dynamodb-update-item
     ├── POST /dynamodb/delete-item    → Lambda: dynamodb-delete-item
     ├── POST /dynamodb/query          → Lambda: dynamodb-query
     ├── POST /dynamodb/scan           → Lambda: dynamodb-scan
     ├── POST /dynamodb/batch-get      → Lambda: dynamodb-batch-get
     ├── POST /dynamodb/list-tables    → Lambda: dynamodb-list-tables
     ├── POST /dynamodb/describe-table → Lambda: dynamodb-describe-table
     └── POST /dynamodb/count-items    → Lambda: dynamodb-count-items
                │
                ▼
          AWS DynamoDB
```

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform installed
- `jq`, `bash 4+`, `curl`, `openssl` (for proxy)
- AWS account with DynamoDB access

## Sample Table (Optional)

The project includes an optional sample "Users" table with 10 pre-populated user records for testing purposes.

**To use the sample table:**
- Leave `01-lambdas/sample-table.tf` as-is during deployment

**To skip the sample table:**
- Rename the file: `mv 01-lambdas/sample-table.tf 01-lambdas/sample-table.tf.disabled`
- OR delete it: `rm 01-lambdas/sample-table.tf`
- OR comment out all resources in the file

The sample Users table includes:
- Primary key: `userId` (String)
- Global Secondary Index on `email`
- 10 sample users with fields: userId, name, email, age, role, department, active, joinDate
- Pay-per-request billing (no fixed costs)

## Quick Start

### For Linux/Mac

#### 1. Deploy the Infrastructure

```bash
./apply.sh
```

This will:
1. Run environment checks
2. Deploy all Lambda functions and API Gateway using Terraform
3. Generate proxy configuration with credentials from Secrets Manager
4. Run validation tests

### For Windows (PowerShell)

#### 1. Deploy the Infrastructure

```powershell
.\scripts-powershell\apply.ps1
```

This will:
1. Run environment checks
2. Deploy all Lambda functions and API Gateway using Terraform
3. Generate proxy configuration with credentials from Secrets Manager
4. Run validation tests

### 2. Configure Claude Desktop

Copy the contents of `configs/claude_desktop_config_sh.json` into your Claude Desktop configuration file:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### 3. Restart Claude Desktop

The DynamoDB tools will now be available in your Claude Desktop conversations.

## Available Tools

### Read Operations

1. **dynamodb_get_item** - Retrieve a single item by primary key
   ```json
   {
     "table_name": "Users",
     "key": {"userId": "123"}
   }
   ```

2. **dynamodb_query** - Query items using partition key
   ```json
   {
     "table_name": "Orders",
     "key_condition_expression": "#pk = :pk",
     "expression_attribute_names": {"#pk": "userId"},
     "expression_attribute_values": {":pk": "user123"}
   }
   ```

3. **dynamodb_scan** - Scan entire table or with filters
   ```json
   {
     "table_name": "Products",
     "limit": 10
   }
   ```

4. **dynamodb_batch_get** - Get multiple items in one request
   ```json
   {
     "table_name": "Users",
     "keys": [{"userId": "1"}, {"userId": "2"}]
   }
   ```

5. **dynamodb_list_tables** - List all DynamoDB tables
   ```json
   {}
   ```

6. **dynamodb_describe_table** - Get table metadata and schema
   ```json
   {
     "table_name": "Users"
   }
   ```

7. **dynamodb_count_items** - Get approximate item count
   ```json
   {
     "table_name": "Users"
   }
   ```

### Write Operations

8. **dynamodb_put_item** - Add or replace an item
   ```json
   {
     "table_name": "Users",
     "item": {
       "userId": "123",
       "name": "John Doe",
       "email": "john@example.com"
     }
   }
   ```

9. **dynamodb_update_item** - Update specific attributes
   ```json
   {
     "table_name": "Users",
     "key": {"userId": "123"},
     "update_expression": "SET #name = :name",
     "expression_attribute_names": {"#name": "name"},
     "expression_attribute_values": {":name": "Jane Doe"}
   }
   ```

10. **dynamodb_delete_item** - Delete an item by key
    ```json
    {
      "table_name": "Users",
      "key": {"userId": "123"}
    }
    ```

## Project Structure

```
.
├── 01-lambdas/               # Terraform and Lambda code
│   ├── code/
│   │   └── dynamodb_ops.py   # All Lambda handlers
│   ├── main.tf               # AWS provider and data sources
│   ├── api.tf                # API Gateway configuration
│   ├── iam-proxy-user.tf     # IAM user for proxy
│   ├── lambda-tools.tf       # Tool registry Lambda
│   ├── lambda-get-item.tf    # GetItem Lambda
│   ├── lambda-put-item.tf    # PutItem Lambda
│   ├── sample-table.tf       # Optional sample Users table
│   └── ...                   # Other Lambda configurations
├── 02-proxy/
│   ├── proxy.sh              # MCP proxy script (bash)
│   └── proxy.ps1             # MCP proxy script (PowerShell)
├── configs/                  # Configuration files
│   ├── claude_desktop_config_sh.json  # Generated MCP config
│   ├── mcp-config-powershell.json     # PowerShell MCP template
│   ├── mcp-config-fixed.json          # Bash MCP template
│   └── test-output.json               # Test output samples
├── scripts-powershell/       # PowerShell scripts
│   ├── apply.ps1             # Deployment script (Windows)
│   ├── validate.ps1          # Validation tests (Windows)
│   ├── check_env.ps1         # Environment checks (Windows)
│   ├── fix-time.ps1          # Time sync utility (Windows)
│   └── ...                   # Other PowerShell utilities
├── apply.sh                  # Deployment script (Linux/Mac)
├── destroy.sh                # Teardown script
├── validate.sh               # Validation tests (Linux/Mac)
├── check_env.sh              # Pre-flight checks (Linux/Mac)
└── README.md                 # This file
```

## Security

- All API routes require AWS IAM authorization
- Proxy signs requests with SigV4
- IAM user has least-privilege permissions (execute-api:Invoke only)
- Credentials stored in AWS Secrets Manager
- Each Lambda has scoped DynamoDB permissions

## IAM Permissions

The Lambda functions require these DynamoDB permissions (configured automatically):
- `dynamodb:GetItem`
- `dynamodb:PutItem`
- `dynamodb:UpdateItem`
- `dynamodb:DeleteItem`
- `dynamodb:Query`
- `dynamodb:Scan`
- `dynamodb:BatchGetItem`
- `dynamodb:ListTables`
- `dynamodb:DescribeTable`

## Cleanup

To remove all deployed resources:

```bash
./destroy.sh
```

## Troubleshooting

### Validation Tests Fail

If validation shows errors about missing tables, this is expected if you haven't created any DynamoDB tables yet. The Lambda functions are working correctly if they return proper error messages.

### Authentication Errors

Ensure your AWS credentials have permissions to:
- Deploy Lambda functions
- Create API Gateway resources
- Manage IAM users and policies
- Access Secrets Manager

### Proxy Connection Issues

Check that:
- Environment variables are correctly set in the Claude Desktop config
- API Gateway endpoint is accessible
- IAM user credentials are valid

## Example Usage

Ask Claude:

**Basic Queries:**
- "List all my DynamoDB tables"
- "Describe the Users table"
- "How many items are in the Users table?"

**With Sample Table:**
- "Get the user with userId 'user001' from the Users table"
- "Scan the Users table and show me all users"
- "Query the Users table for all active users"
- "Show me all users in the Engineering department"
- "Get users user001, user002, and user003 from the Users table using batch get"

**Write Operations:**
- "Add a new user with userId 'user011', name 'Kate Brown', and email 'kate@example.com' to the Users table"
- "Update the role to 'Senior Engineer' for user001 in the Users table"
- "Delete the user with userId 'user005' from the Users table"

## License

MIT
