# Terraform Provider AzureRM Reviewer

## Overview

This tool provides automated code review capabilities for pull requests of new resources in the [AzureRM Terraform Provider](https://github.com/hashicorp/terraform-provider-azurerm).

## Important Limitations

- This tool only reviews newly added files in a pull request.
- It may produce false positives or miss certain types of errors.
- It may take longer than standard linter tools due to the processing time of the AI API.

## Prerequisites

- [Install PowerShell](https://learn.microsoft.com/powershell/scripting/install/install-powershell)
- [Install and Login GitHub CLI](https://cli.github.com/)
- [Install and Login Copilot CLI](https://github.com/features/copilot/cli)

## Usage

1. Clone the repository:

    ```bash
    git clone https://github.com/ms-zhenhua/terraform-provider-azurerm-reviewer.git
    cd terraform-provider-azurerm-reviewer
    ```

2. Review a pull request (e.g., id=10000):

    ```powershell
    .\scripts\review_pull_request.ps1 "https://github.com/hashicorp/terraform-provider-azurerm/pull/10000" -Model "gpt-4o" -MaxParallel 3
    ```

    If everything goes well, you will get a final result at `./pull_requests/hashicorp_terraform-provider-azurerm_10000/report.md`.

### Configuration Parameters

| Parameter | Description |
| :--- | :--- |
| `Model` | The LLM Model used for reviewing the code. |
| `MaxParallel` | Max parallel review tasks. Note: If the value is too high, the AI API may return errors. |
| `ForceNew` | Switch to restart reviewing the pull request from scratch. |