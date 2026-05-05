# CLAUDE.md — aws-serverless-mcp-dynamodb

A serverless AWS DynamoDB API designed for MCP (Model Context Protocol) tool use.
Eleven Lambda functions expose DynamoDB operation tools behind an API Gateway HTTP API with
AWS_IAM authorization. A local MCP proxy (`02-proxy/`) signs requests with SigV4,
making the remote serverless API transparent to the AI caller.

---

## What This Project Does

An AI assistant calls MCP tools that appear local but are backed by Lambda functions
running in AWS. Each tool performs DynamoDB operations and returns a plain-text
summary suitable for direct narration — not raw DynamoDB JSON.

The proxy self-configures at startup by calling `GET /tools`, so route mappings and
tool schemas are defined once in `dynamodb_ops.py` with no hardcoding in the proxy.

**Base URL after deploy:**
```
https://{api-id}.execute-api.us-east-1.amazonaws.com
```

| Tool Name | Route | Lambda | Operation |
|-----------|-------|--------|-----------|
| *(proxy startup)* | `GET /tools` | dynamodb-tools | Tool registry for proxy self-config |
| dynamodb_get_item | `POST /dynamodb/get-item` | dynamodb-get-item | Get single item by key |
| dynamodb_put_item | `POST /dynamodb/put-item` | dynamodb-put-item | Add/replace item |
| dynamodb_update_item | `POST /dynamodb/update-item` | dynamodb-update-item | Update attributes |
| dynamodb_delete_item | `POST /dynamodb/delete-item` | dynamodb-delete-item | Delete item |
| dynamodb_query | `POST /dynamodb/query` | dynamodb-query | Query by partition key |
| dynamodb_scan | `POST /dynamodb/scan` | dynamodb-scan | Scan table |
| dynamodb_batch_get | `POST /dynamodb/batch-get` | dynamodb-batch-get | Get multiple items |
| dynamodb_list_tables | `POST /dynamodb/list-tables` | dynamodb-list-tables | List all tables |
| dynamodb_describe_table | `POST /dynamodb/describe-table` | dynamodb-describe-table | Get table metadata |
| dynamodb_count_items | `POST /dynamodb/count-items` | dynamodb-count-items | Get item count |

---

## Architecture

```
AI assistant (MCP client)
     │  stdio / JSON-RPC
     ▼
02-proxy/proxy.sh  ← holds IAM credentials, signs with SigV4
     │  HTTPS + AWS_IAM auth
     ▼
API Gateway (HTTP API v2) — dynamodb-api
     │  routes by method + path
     ├── GET  /tools                   → Lambda: dynamodb-tools (proxy startup)
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

**Why plain-text responses:** DynamoDB returns nested attribute structures in complex
JSON format. Returning pre-formatted summaries lets the AI narrate results without
parsing and keeps the MCP tool contract simple.

**Why IAM auth:** The proxy signs every request with the caller's AWS credentials.
API Gateway enforces IAM authorization before the Lambda is invoked — no API keys
to rotate and no unauthenticated access possible.

**Why a tool-discovery route:** Adding a tool only requires updating `dynamodb_ops.py`
and redeploying — the proxy loads its route map from `GET /tools` at startup with no
hardcoded definitions.

---

## Repository Layout

```
01-lambdas/
  code/
    dynamodb_ops.py           All eleven handler functions (single file, single ZIP)
  main.tf                     Terraform: AWS provider, data sources, archive_file
  api.tf                      Terraform: HTTP API, 11 routes (AWS_IAM), integrations, stage
  lambda-tools.tf             Terraform: IAM role + Lambda for dynamodb-tools
  lambda-get-item.tf          Terraform: IAM role + Lambda for get-item
  lambda-put-item.tf          Terraform: IAM role + Lambda for put-item
  lambda-update-item.tf       Terraform: IAM role + Lambda for update-item
  lambda-delete-item.tf       Terraform: IAM role + Lambda for delete-item
  lambda-query.tf             Terraform: IAM role + Lambda for query
  lambda-scan.tf              Terraform: IAM role + Lambda for scan
  lambda-batch-get.tf         Terraform: IAM role + Lambda for batch-get
  lambda-list-tables.tf       Terraform: IAM role + Lambda for list-tables
  lambda-describe-table.tf    Terraform: IAM role + Lambda for describe-table
  lambda-count-items.tf       Terraform: IAM role + Lambda for count-items
  iam-proxy-user.tf           Terraform: IAM user + access key + Secrets Manager secret
  sample-table.tf             OPTIONAL: Sample Users table with 10 test records
02-proxy/
  proxy.sh                    Bash MCP stdio proxy (SigV4 signing, JSON-RPC dispatcher)
  claude_desktop_config_sh.json   Generated Claude Desktop config
check_env.sh                  Pre-flight: verify aws/terraform/jq, test AWS credentials
apply.sh                      Full deployment + config generation + validation
destroy.sh                    Teardown
validate.sh                   Smoke test via direct Lambda invocation
```

---

## Prerequisites

- `aws`, `terraform`, `jq`, `envsubst` in PATH
- `bash 4+`, `curl`, `openssl` (for `proxy.sh`)
- AWS credentials configured with permissions:
  - Lambda, API Gateway, IAM, Secrets Manager (for deploy)
  - DynamoDB permissions for Lambda execution roles
- DynamoDB tables in your AWS account (or create them)

## Optional Sample Table

The project includes `01-lambdas/sample-table.tf` which creates a sample "Users" table
with 10 pre-populated user records for testing and demonstration purposes.

**Table Schema:**
- Table name: `Users`
- Primary key: `userId` (String)
- Global Secondary Index: `EmailIndex` on `email` attribute
- Billing mode: Pay-per-request (no fixed costs)

**Sample Data:** 10 users (user001-user010) with attributes:
- userId, name, email, age, role, department, active, joinDate

**To skip the sample table:**
Rename, delete, or comment out `01-lambdas/sample-table.tf` before deploying.

---

## Deployment

```bash
# Full deploy
./apply.sh

# Teardown
./destroy.sh

# Smoke test only (after deploy)
./validate.sh
```

`apply.sh` runs in one sequence:
1. **`check_env.sh`** → validates tools and AWS credentials
2. **`01-lambdas`** → deploys all eleven Lambdas, API Gateway, IAM roles, IAM proxy
   user, and Secrets Manager secret
3. **Config generation** → fetches proxy credentials from Secrets Manager and generates
   `02-proxy/claude_desktop_config_sh.json`
4. **`validate.sh`** → invokes each Lambda directly and prints the plain-text output

---

## Terraform Modules

### 01-lambdas
- Eleven `aws_lambda_function` resources (Python 3.13, 15s timeout), one per tool
- Eleven `aws_iam_role` resources with scoped DynamoDB policies (least-privilege):
  - `dynamodb:GetItem` for get-item
  - `dynamodb:PutItem` for put-item
  - `dynamodb:UpdateItem` for update-item
  - `dynamodb:DeleteItem` for delete-item
  - `dynamodb:Query` for query
  - `dynamodb:Scan` for scan
  - `dynamodb:BatchGetItem` for batch-get
  - `dynamodb:ListTables` for list-tables
  - `dynamodb:DescribeTable` for describe-table and count-items
  - No DynamoDB permissions for dynamodb-tools (returns static registry only)
- `aws_apigatewayv2_api` `dynamodb-api` — HTTP API (no CORS, IAM auth only)
- Eleven `aws_apigatewayv2_integration` + `aws_apigatewayv2_route` pairs
- All routes: `authorization_type = "AWS_IAM"`
- `aws_apigatewayv2_stage` `$default` with auto_deploy
- Eleven `aws_lambda_permission` resources granting API Gateway invoke rights
- `aws_iam_user` `dynamodb-mcp-proxy` with inline `execute-api:Invoke` policy scoped
  to this API's execution ARN
- `aws_iam_access_key` for the proxy user
- `aws_secretsmanager_secret` `dynamodb-mcp-proxy` storing credentials and endpoint

---

## Lambda Code

All eleven handlers live in `dynamodb_ops.py` and follow the same pattern:
- Parse JSON body from API Gateway event
- Convert simple key/item format to DynamoDB format (type wrappers)
- Call `boto3.client("dynamodb")` with appropriate operation
- Return `{"statusCode": 200, "headers": {"Content-Type": "text/plain"}, "body": "..."}`
- Body is a human-readable plain-text summary, not raw DynamoDB JSON
- Handle `ClientError` exceptions gracefully

The `tools_handler` is the exception — it returns `Content-Type: application/json`
with the `TOOL_REGISTRY` array (name, description, inputSchema, route per tool).

**DynamoDB type conversion:**
The Lambda handlers automatically convert between simple JSON types and DynamoDB's
typed attribute format:
- String → `{"S": "value"}`
- Number → `{"N": "123"}`
- Boolean → `{"BOOL": true}`
- Map → `{"M": {...}}`
- List → `{"L": [...]}`

---

## MCP Proxy

`02-proxy/proxy.sh` is a stdio MCP server:
- Reads JSON-RPC 2.0 messages from stdin, writes responses to stdout
- On startup calls `GET /tools` (SigV4 signed) to populate its route map and tool list
- Signs all API Gateway requests with AWS SigV4 using credentials from env vars
- Handles `initialize`, `tools/list`, and `tools/call` methods
- Passes tool arguments as JSON body to the Lambda functions

Required environment variables (populated by the generated config file):
```
MCP_ACCESS_KEY_ID      IAM access key for the dynamodb-mcp-proxy user
MCP_SECRET_ACCESS_KEY  IAM secret key for the dynamodb-mcp-proxy user
MCP_API_ENDPOINT       API Gateway invoke URL (no trailing slash)
MCP_REGION             AWS region (default: us-east-1)
```

After `./apply.sh`, copy the contents of `02-proxy/claude_desktop_config_sh.json`
into your Claude Desktop `claude_desktop_config.json`.

---

## Test Manually

```bash
# Invoke any tool directly (no SigV4 needed for direct Lambda calls)
aws lambda invoke \
  --function-name dynamodb-list-tables \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/out.json && jq -r '.body' /tmp/out.json

# Get item example (using sample table)
aws lambda invoke \
  --function-name dynamodb-get-item \
  --payload '{"table_name":"Users","key":{"userId":"user001"}}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/out.json && jq -r '.body' /tmp/out.json
```

---

## Example Queries

Once configured in Claude Desktop, you can ask:

**Basic operations:**
- "List all my DynamoDB tables"
- "Describe the Users table"
- "How many items are in the Users table?"

**With sample table (if deployed):**
- "Get the user with userId 'user001' from the Users table"
- "Scan the Users table and show me all users"
- "Show me all users in the Engineering department"
- "Get users user001, user002, and user003 from the Users table using batch get"

**Write operations:**
- "Add a new user to the Users table with userId 'user011', name 'Kate Brown', and email 'kate@example.com'"
- "Update the role to 'Senior Engineer' for user001 in the Users table"
- "Delete the user with userId 'user005' from the Users table"

---

## Security Notes

- All routes require AWS_IAM authorization
- IAM user has minimal permissions (execute-api:Invoke only)
- Each Lambda has scoped DynamoDB permissions (principle of least privilege)
- Credentials stored in AWS Secrets Manager, not in code
- No API keys or secrets in repository or proxy script

---

## Extending the API

To add a new DynamoDB operation:

1. Add handler function to `01-lambdas/code/dynamodb_ops.py`
2. Add tool definition to `TOOL_REGISTRY` in same file
3. Create new `lambda-*.tf` file with IAM role and Lambda function
4. Add integration, route, and permission to `01-lambdas/api.tf`
5. Redeploy with `./apply.sh`

The proxy automatically discovers the new tool on next startup.
