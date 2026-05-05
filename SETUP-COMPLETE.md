# DynamoDB MCP Setup Complete! 🎉

Your serverless DynamoDB MCP infrastructure has been successfully deployed to AWS!

## What Was Created

✅ **11 Lambda Functions** for DynamoDB operations
✅ **API Gateway** with secure IAM authentication
✅ **IAM User** (dynamodb-mcp-proxy) with limited permissions
✅ **Secrets Manager** secret with credentials
✅ **Sample DynamoDB Table** (Users) with 10 test records
✅ **MCP Proxy Configuration** ready for Claude Desktop

## AWS Resources Summary

- **API Endpoint**: https://4h8r7qhmpa.execute-api.us-east-1.amazonaws.com/
- **Region**: us-east-1
- **Sample Table**: Users (with 10 test records)

## Next Steps: Configure Claude Desktop

### Step 1: Locate Claude Desktop Config File

The config file location depends on your OS:

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```
Or typically:
```
C:\Users\Naveen\AppData\Roaming\Claude\claude_desktop_config.json
```

**Mac:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Linux:**
```
~/.config/Claude/claude_desktop_config.json
```

### Step 2: Add MCP Server Configuration

1. Open the Claude Desktop config file in a text editor
2. If the file doesn't exist, create it with this content:

```json
{
  "mcpServers": {
    "dynamodb": {
      "command": "bash",
      "args": ["C:/Users/Naveen/Downloads/Serverless-DynamoDB-MCP/02-proxy/proxy.sh"],
      "env": {
        "MCP_ACCESS_KEY_ID": "YOUR_AWS_ACCESS_KEY_ID",
        "MCP_SECRET_ACCESS_KEY": "YOUR_AWS_SECRET_ACCESS_KEY",
        "MCP_API_ENDPOINT": "https://4h8r7qhmpa.execute-api.us-east-1.amazonaws.com/",
        "MCP_REGION": "us-east-1"
      }
    }
  }
}
```

3. If the file already exists with other MCP servers, add the "dynamodb" entry to the existing "mcpServers" object

### Step 3: Restart Claude Desktop

Close and reopen Claude Desktop for the changes to take effect.

### Step 4: Verify the Connection

In Claude Desktop, you should see the DynamoDB MCP server connected. Try asking Claude:

- "List all DynamoDB tables"
- "Describe the Users table"
- "Query the Users table for all records"
- "Get user with ID user001 from the Users table"

## Available Tools

Your MCP server provides these DynamoDB operations:

1. **list_tables** - List all DynamoDB tables
2. **describe_table** - Get table schema and metadata
3. **get_item** - Retrieve a single item by key
4. **put_item** - Create or update an item
5. **update_item** - Update specific attributes
6. **delete_item** - Delete an item
7. **query** - Query items with conditions
8. **scan** - Scan table with optional filters
9. **batch_get** - Get multiple items at once
10. **count_items** - Count items in a table

## Sample Data

The Users table has been pre-populated with 10 test users (user001 through user010). Each user has:
- userId (partition key)
- name
- email
- status (active/inactive)
- createdAt timestamp

## Troubleshooting

### MCP Server Not Connecting

1. Verify bash is available in your PATH
2. Check that the proxy.sh path is correct
3. Ensure the credentials are correct
4. Check Claude Desktop logs for errors

### Permission Errors

The IAM user has limited permissions to:
- Invoke API Gateway endpoints
- Only the specific API created by this deployment

### Time Sync Issues

If you see signature errors, sync your system time:
```powershell
.\fix-time.ps1
```

## Cleanup

To remove all AWS resources:

```powershell
cd 01-lambdas
terraform destroy -auto-approve
```

## Security Notes

⚠️ **Important**: The credentials in the config file provide access to your DynamoDB tables through the API Gateway. Keep them secure!

- The IAM user has minimal permissions (only API Gateway invoke)
- All requests are signed with AWS SigV4
- API Gateway uses IAM authentication
- Credentials are stored in AWS Secrets Manager

## Support

For issues or questions:
- Check the README.md for detailed documentation
- Review Terraform outputs: `cd 01-lambdas && terraform output`
- Check Lambda logs in CloudWatch
- Verify API Gateway in AWS Console

---

**Deployment Date**: 2026-05-06
**AWS Account**: 478468758108
**Region**: us-east-1
