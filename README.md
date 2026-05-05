# AWS-Serverless-Dynamodb-MCP-Server

> **A fully serverless Model Context Protocol (MCP) backend on AWS that enables AI assistants to interact with DynamoDB tables conversationally — built, deployed, and documented by me as a complete end-to-end implementation.**

---

## 📌 Project Overview

This project implements a **serverless MCP backend** that bridges AI assistants (like Claude via Kiro IDE) with Amazon DynamoDB. Instead of writing code or queries, you can talk to your database in plain English. The architecture leverages AWS Lambda, API Gateway (HTTP API v2), IAM with SigV4 request signing, and a local proxy to handle transparent MCP communication.

The system exposes **10 fully functional DynamoDB tools** through the MCP protocol, covering everything from reading individual records to batch operations, scans, queries, and full CRUD support — all secured with AWS IAM authorization.
---

## 🏗️ Architecture
![Architecture Diagram](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/000c29909a3bd5a73efeb5260695a40b1bdf740b/Gemini_Generated_Image_r84cvar84cvar84c.png)

## ✅ Features

- **10 DynamoDB Operations**: GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, ListTables, DescribeTable, CountItems
- **Serverless Architecture**: Every operation runs on AWS Lambda — no servers to manage
- **Secure by Default**: All routes protected with AWS IAM authorization and SigV4 request signing
- **Self-Configuring Proxy**: Dynamic tool discovery from the backend at startup
- **Plain-Text Responses**: Human-readable output optimized for AI assistants
- **Cross-Platform Support**: Bash scripts for Linux/Mac, PowerShell scripts for Windows
- **Optional Sample Table**: Pre-populated Users table with 10 records for immediate testing

---

## 🔧 Prerequisites

Before deploying, ensure the following tools are installed and configured:

- **AWS CLI** — configured with valid credentials (`aws configure`)
- **Terraform** — for infrastructure provisioning
- **jq** — for JSON processing in bash scripts
- **bash 4+** / **PowerShell 5.1+** — depending on your OS
- **curl** and **openssl** — used by the proxy for SigV4 signing
- **AWS Account** — with IAM permissions to deploy Lambda, API Gateway, and DynamoDB

---

## 🚀 Deployment

### Environment Verification

Before deploying, I ran the environment check script to confirm all required tools and AWS credentials were properly configured:

![Environment Check Passed](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(607).png?raw=true)

*The environment check verified AWS CLI, Terraform, jq, and valid AWS credentials (Account: 478468758108, Identity: arn:aws:iam::478468758108:user/Naveen) — all passed successfully.*

---

### Infrastructure Deployment (Windows / PowerShell)

I deployed the full infrastructure using the PowerShell deployment script:

```powershell
.\apply.ps1
```

The script automatically:
1. Runs environment pre-flight checks
2. Deploys all Lambda functions and API Gateway using Terraform
3. Generates proxy configuration with credentials from Secrets Manager
4. Runs validation tests

![Deployment in Progress](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(615).png?raw=true)

*Terraform initializing provider plugins (hashicorp/aws v6.43.0, hashicorp/archive v2.7.1) and deploying Lambda functions and API Gateway.*

---

### Deployment Complete

![Deployment Output](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%202026-05-06%20021303.png?raw=true)

*Terraform outputs confirm successful deployment: sample Users table created in `us-east-1` with 10 pre-populated records, proxy configuration generated at `02-proxy\claude_desktop_config_sh.json`, and all 4 deployment stages completed.*

---

## 🔌 MCP Server Integration with Kiro IDE

After deployment, I configured the MCP server in Kiro IDE. The server connected successfully and registered all **10 DynamoDB tools**:

![MCP Server Connected — 10 Tools](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(608).png?raw=true)

*The left panel shows the MCP Server `dynamodb` as **Connected (10 tools)**. The MCP logs confirm `[dynamodb] Connected to server with transport type: Stdio` and `Successfully connected and synced tools and resources for MCP server`. The tool list shows all operations — get, put, update, delete, query, scan, batch_get, list_tables, describe_table, and count_items.*

### MCP Configuration

```json
{
  "mcpServers": {
    "dynamodb": {
      "command": "bash",
      "args": ["./02-proxy/proxy.sh"],
      "env": {
        "API_ENDPOINT": "<your-api-gateway-url>",
        "AWS_ACCESS_KEY_ID": "<from-secrets-manager>",
        "AWS_SECRET_ACCESS_KEY": "<from-secrets-manager>",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

---

## 🛠️ Available Tools

### Read Operations

| Tool | Description |
|------|-------------|
| `dynamodb_get_item` | Retrieve a single item by primary key |
| `dynamodb_query` | Query items using partition key and optional filters |
| `dynamodb_scan` | Scan an entire table or apply filter expressions |
| `dynamodb_batch_get` | Retrieve multiple items in a single request |
| `dynamodb_list_tables` | List all DynamoDB tables in the account |
| `dynamodb_describe_table` | Get table metadata, schema, and index info |
| `dynamodb_count_items` | Get approximate item count for a table |

### Write Operations

| Tool | Description |
|------|-------------|
| `dynamodb_put_item` | Add or replace a complete item |
| `dynamodb_update_item` | Update specific attributes of an existing item |
| `dynamodb_delete_item` | Delete an item by its primary key |

---

## 📊 Live Demo — Operations Walkthrough

### 1. Batch Get — Retrieving Multiple Users

I asked Kiro to fetch users user001, user002, and user003 in a single batch request:

![Batch Get Users](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(610).png?raw=true)

*The `dynamodb_batch_get` tool retrieved all three users in one API call. Results show Carol Davis (user003 — Engineering Manager, 42), Bob Smith (user002 — Product Manager, 35), and Alice Johnson (user001 — Software Engineer, 28) with full attribute details.*

**Example input:**
```json
{
  "table_name": "Users",
  "keys": [
    {"userId": "user001"},
    {"userId": "user002"},
    {"userId": "user003"}
  ]
}
```

---

### 2. Put Item — Adding a New User

I added a new user (Kate Brown) to the Users table via natural language:

> *"Add a new user with userId 'user011', name 'Kate Brown', and email 'kate@example.com' to the Users table"*

![Put Item — Kate Brown Added](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(609).png?raw=true)

*The `dynamodb_put_item` tool was called with the correct payload and returned `Successfully added/updated item in table 'Users'`. Kiro confirmed: "Successfully added Kate Brown to the Users table with userId 'user011' and email 'kate@example.com'."*

**Tool call payload:**
```json
{
  "table_name": "Users",
  "item": {
    "userId": "user011",
    "name": "Kate Brown",
    "email": "kate@example.com"
  }
}
```

---

### 3. Update Item — Promoting Alice Johnson

I updated Alice Johnson's role from "Software Engineer" to "Senior Engineer":

> *"Update the role to 'Senior Engineer' for user001 in the Users table"*

![Update Item — Role Updated](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(611).png?raw=true)

*The `dynamodb_update_item` tool used a proper DynamoDB update expression with attribute name aliasing (`#role`) to avoid reserved word conflicts. The result shows Alice Johnson's record updated with `role: Senior Engineer`. Kiro confirmed the role change from "Software Engineer" to "Senior Engineer".*

**Tool call payload:**
```json
{
  "table_name": "Users",
  "key": {"userId": "user001"},
  "update_expression": "SET #role = :newRole",
  "expression_attribute_names": {"#role": "role"},
  "expression_attribute_values": {":newRole": "Senior Engineer"}
}
```

---

### 4. Delete Item — Removing a User

I deleted user005 (Emma Wilson) from the table:

> *"Delete the user with userId 'user005' from the Users table"*

![Delete Item — user005 Deleted](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(612).png?raw=true)

*The `dynamodb_delete_item` tool was called with `{"userId": "user005"}` as the key and returned `Successfully deleted item from table 'Users' with key: {"userId": "user005"}`. Kiro confirmed deletion of Emma Wilson.*

---

### 5. Scan — Viewing All Users After Operations

After adding Kate Brown and deleting Emma Wilson, I scanned the full table to confirm the state:

![Full Table Scan Results](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(613).png?raw=true)

*The scan returned all 10 current users. The results correctly reflect all previous operations: Alice Johnson now shows as Senior Engineer (updated), Kate Brown (user011) appears as the newly added user, and Emma Wilson (user005) is absent — confirming the delete was successful.*

**Final table state after all operations:**
1. David Lee (user004) — DevOps Engineer, Engineering
2. Bob Smith (user002) — Product Manager, Product
3. Grace Chen (user007) — Frontend Developer, Engineering
4. Iris Anderson (user009) — Security Engineer, Security
5. Alice Johnson (user001) — **Senior Engineer**, Engineering *(updated)*
6. Jack Robinson (user010) — Backend Developer, Engineering
7. Frank Martinez (user006) — Data Scientist, Data
8. Carol Davis (user003) — Engineering Manager, Engineering
9. Henry Taylor (user008) — VP of Engineering, Engineering
10. Kate Brown (user011) — *(newly added user)*

---

### 6. Query — Finding All Active Users

I queried the table to find all users with `active: True`:

> *"Query the Users table for all active users"*

![Active Users Query](https://github.com/Naveen15github/AWS-Serverless-Dynamodb-MCP-Server/blob/6243a94c476b8c2e612b5a19f7093c80e564f0f0/Screenshot%20(614).png?raw=true)

*The scan with filter correctly identified 9 users with `active: True`. Kate Brown (user011) was noted as not having the active attribute set yet — expected since she was added without that field. All other 9 users are active.*

---

## 📁 Project Structure

```
.
├── 01-lambdas/                    # Terraform configurations & Lambda code
│   ├── code/
│   │   └── dynamodb_ops.py        # All 10 Lambda handlers in one file
│   ├── main.tf                    # AWS provider and data sources
│   ├── api.tf                     # API Gateway HTTP API v2 configuration
│   ├── iam-proxy-user.tf          # IAM user for proxy with least-privilege
│   ├── lambda-tools.tf            # Tool registry Lambda (GET /tools)
│   ├── lambda-get-item.tf         # GetItem Lambda
│   ├── lambda-put-item.tf         # PutItem Lambda
│   ├── lambda-update-item.tf      # UpdateItem Lambda
│   ├── lambda-delete-item.tf      # DeleteItem Lambda
│   ├── lambda-query.tf            # Query Lambda
│   ├── lambda-scan.tf             # Scan Lambda
│   ├── lambda-batch-get.tf        # BatchGet Lambda
│   ├── lambda-list-tables.tf      # ListTables Lambda
│   ├── lambda-describe-table.tf   # DescribeTable Lambda
│   ├── lambda-count-items.tf      # CountItems Lambda
│   └── sample-table.tf            # Optional sample Users table (10 records)
├── 02-proxy/
│   ├── proxy.sh                   # MCP proxy script (bash — Linux/Mac)
│   └── proxy.ps1                  # MCP proxy script (PowerShell — Windows)
├── configs/
│   ├── claude_desktop_config_sh.json   # Generated MCP config (auto-created)
│   ├── mcp-config-powershell.json      # PowerShell MCP template
│   ├── mcp-config-fixed.json           # Bash MCP template
│   └── test-output.json                # Sample test outputs
├── scripts-powershell/            # Windows PowerShell scripts
│   ├── apply.ps1                  # Full deployment script
│   ├── validate.ps1               # Validation tests
│   ├── check_env.ps1              # Environment pre-flight checks
│   ├── fix-time.ps1               # Clock sync utility (SigV4 requirement)
│   └── ...
├── apply.sh                       # Deployment script (Linux/Mac)
├── destroy.sh                     # Full teardown script
├── validate.sh                    # Post-deployment validation (Linux/Mac)
├── check_env.sh                   # Environment checks (Linux/Mac)
└── README.md                      # This file
```

---

## 🔒 Security Design

Security was a first-class concern throughout this implementation:

- **AWS IAM Authorization** on every API Gateway route — no public endpoints
- **SigV4 Request Signing** — the proxy signs every request with AWS credentials before sending to API Gateway
- **Least-Privilege IAM** — the proxy IAM user has only `execute-api:Invoke` permission; nothing more
- **Scoped Lambda Permissions** — each Lambda function has only the DynamoDB permissions it needs
- **Secrets Manager** — IAM credentials are stored in AWS Secrets Manager and injected at config generation time, never hardcoded

### IAM Permissions per Lambda

| Permission | Used By |
|-----------|---------|
| `dynamodb:GetItem` | get-item Lambda |
| `dynamodb:PutItem` | put-item Lambda |
| `dynamodb:UpdateItem` | update-item Lambda |
| `dynamodb:DeleteItem` | delete-item Lambda |
| `dynamodb:Query` | query Lambda |
| `dynamodb:Scan` | scan, count-items Lambdas |
| `dynamodb:BatchGetItem` | batch-get Lambda |
| `dynamodb:ListTables` | list-tables Lambda |
| `dynamodb:DescribeTable` | describe-table Lambda |

---

## 🧪 Sample Table

The project includes an optional sample **Users** table pre-populated with 10 records for immediate testing:

- **Primary Key**: `userId` (String)
- **GSI**: On `email` field
- **Billing**: Pay-per-request (no fixed costs)
- **Sample Fields**: userId, name, email, age, role, department, active, joinDate

**To skip the sample table:**
```bash
# Option 1: Rename
mv 01-lambdas/sample-table.tf 01-lambdas/sample-table.tf.disabled

# Option 2: Delete
rm 01-lambdas/sample-table.tf
```

---

## 💬 Example Conversations

Here are natural language prompts you can use once connected:

**Inspection:**
- *"List all my DynamoDB tables"*
- *"Describe the Users table"*
- *"How many items are in the Users table?"*

**Reading Data:**
- *"Get the user with userId 'user001' from the Users table"*
- *"Scan the Users table and show me all users"*
- *"Query the Users table for all active users"*
- *"Show me all users in the Engineering department"*
- *"Get users user001, user002, and user003 using batch get"*

**Writing Data:**
- *"Add a new user with userId 'user011', name 'Kate Brown', and email 'kate@example.com' to the Users table"*
- *"Update the role to 'Senior Engineer' for user001 in the Users table"*
- *"Delete the user with userId 'user005' from the Users table"*

---

## 🧹 Teardown

To remove all AWS resources created by this project:

```bash
# Linux/Mac
./destroy.sh

# Windows
.\scripts-powershell\destroy.ps1
```

This will destroy all Lambda functions, API Gateway, IAM users, Secrets Manager entries, and optionally the DynamoDB sample table.

---

## 🐛 Troubleshooting

### Validation Tests Show Missing Table Errors
This is expected if you haven't created DynamoDB tables yet (or skipped the sample table). The Lambda functions are working correctly if they return proper error messages rather than crashing.

### Authentication / 403 Errors
- Verify your AWS credentials: `aws sts get-caller-identity`
- Check the proxy environment variables match the generated config
- Ensure the IAM user has `execute-api:Invoke` on the deployed API

### Proxy Connection Issues in Kiro / Claude Desktop
- Confirm the `API_ENDPOINT` in your MCP config matches the Terraform output
- Re-run `.\apply.ps1` to regenerate the proxy config if credentials rotated
- On Windows, run `.\scripts-powershell\fix-time.ps1` if SigV4 timestamps are off

### MCP Server Shows "Not Connected"
- Restart the IDE / Claude Desktop after updating the MCP config
- Check the MCP logs for the exact error message
- Ensure `proxy.sh` or `proxy.ps1` has execute permissions

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built end-to-end by Naveen — serverless infrastructure, Lambda functions, IAM security, MCP proxy, and full integration with AI assistants via the Model Context Protocol.*

