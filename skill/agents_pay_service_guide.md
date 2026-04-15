# Agents-Pay-Service API Survival Guide

**Context:** This document is a machine-readable API guide for the `agents-pay-service` (powered by LNbits adapted for SUI/MIST).  
As a "Main Agent" (e.g., Company CEO or Admin Agent), you can programmatically invoke the following RESTful APIs to set up your multi-agent corporate account, allocate isolated wallets for your employee Agents, process payments, and audit financial statistics.

All requests should be mapped to the configured base URL (e.g., `http://127.0.0.1:5000` or `http://127.0.0.1:5002`).

---

## 1. Setting Up the Corporate Account & Agent Wallets

You must create a "Corporate Account" and generate isolated Sub-Wallets (one for each subordinate Agent).
*Note: If this is the very first time, you must hit `POST /api/v1/account` to instantiate an entirely new user account. To create additional sub-wallets under an existing user ID, use the endpoint below.*

**Create a Sub-Agent Wallet**
- **Endpoint:** `POST /api/v1/wallet`
- **Headers:**
  ```http
  X-Api-Key: <Your_Master_Admin_Key_or_Invoice_Key>
  Content-Type: application/json
  ```
- **Payload:**
  ```json
  {
    "name": "Data Analytics Agent Wallet"
  }
  ```
- **Response Validation:**
  The response will return a Wallet object containing `id`, `name`, `balance_msat`, `admin_key`, and `invoice_key`.
  **Action:** You must cache these keys. Give the `admin_key` to the Sub-Agent if it needs spending privileges, or only the `invoice_key` if it only needs read/receive access.

**Batch Create Multiple Wallets (For large-scale Agent deployment)**
To avoid network round-trip overhead, you can spawn dozens or hundreds of Agent wallets in a single API call.
- **Endpoint:** `POST /api/v1/wallet/batch`
- **Headers:**
  ```http
  X-Api-Key: <Your_Master_Admin_Key_or_Invoice_Key>
  Content-Type: application/json
  ```
- **Payload:**
  ```json
  {
    "wallets": [
      { "name": "Agent Worker 001" },
      { "name": "Agent Worker 002" },
      { "name": "Agent Worker 003" }
    ]
  }
  ```
- **Response Validation:**
  The server will process this instantly and return a JSON array `[...]` of created Wallet objects. Each element will contain its distinct `admin_key` and `invoice_key`.

---

## 2. Generating an Invoice (Getting Paid)

When an Agent needs to receive funds (e.g., after completing a task), it must generate an invoice (`payment_request`).

- **Endpoint:** `POST /api/v1/payments`
- **Headers:**
  ```http
  X-Api-Key: <Agent_Invoice_Key_or_Admin_Key>
  Content-Type: application/json
  ```
- **Payload:**
  ```json
  {
    "out": false,
    "amount": 150, 
    "memo": "Data collection task fee",
    "unit": "sat" 
  }
  ```
  *(Note: Due to the SUI bridge, the amount unit maps internally: 1 amount unit = 1 MIST. Some instances may ignore `unit` and use the server default).*
- **Response Validation:**
  Returns a `Payment` generation object including a `payment_request` (a long string beginning with `lnbc` or the mapped prefix). Distribute this string to the Payer.

---

## 3. Paying an Invoice (Transferring Funds)

To settle a requested invoice (payment_request) sent by another Agent.

- **Endpoint:** `POST /api/v1/payments`
- **Headers:**
  ```http
  X-Api-Key: <Payer_Admin_Key>
  Content-Type: application/json
  ```
- **Payload:**
  ```json
  {
    "out": true,
    "bolt11": "<payment_request_string>"
  }
  ```
- **Response Validation:**
  Returns the internal `Payment` object showing success or failure.
  **Bonus:** If the payer and payee belong to the same server backend (e.g., inside the same Company), the payment routes internally as a database-level swap, achieving **0ms latency and 0 transaction routing fees**.

---

## 4. The Direct Internal Treasury Transfer (No-Communication Payment)

If you (the Main Agent) want to deposit an allowance into an employee Agent's wallet without asking them to explicitly generate an invoice, follow this 2-step API combo:

1. **Self-Generation:** Call `POST /api/v1/payments` with `{"out": false, "amount": 50, "memo": "Daily Allowance"}` using the **Sub-Agent's `invoice_key`**. Extract the `payment_request`.
2. **Execution:** Call `POST /api/v1/payments` with `{"out": true, "bolt11": "<payment_request>"}` using your **Treasury `admin_key`**.
*Result:* Funds are instantly teleported.

---

## 5. Financial Auditing & Statistics

Track your company's economic health and verify balances utilizing the stat APIs.

### 5.1 Check Wallet Balance
- **Endpoint:** `GET /api/v1/wallet`
- **Headers:** `X-Api-Key: <Relevant_Invoice_or_Admin_Key>`
- **Response:**
  ```json
  {
    "id": "wallet_alpha_uuid",
    "name": "Data Analytics Agent Wallet",
    "balance": 150000 
  }
  ```
  *(Note: The returned balance is typically represented in `msat`. 1 MIST = 1000 msat, so be sure to divide by 1000 if converting to standard ledger numbers).*

### 5.2 Fetch Payment History & Analytics
- **Endpoint:** `GET /api/v1/payments` *(paginated list)*
- **Headers:** `X-Api-Key: <Relevant_Invoice_or_Admin_Key>`
- **Response:**
  Returns an array of `Payment` models dictating the historical flow.
  
- **Endpoint:** `GET /api/v1/payments/history?group=day` *(aggregated daily stats)*
- **Headers:** `X-Api-Key: <Relevant_Invoice_or_Admin_Key>`
- **Query Parsers:** You can apply filters like `?limit=10&offset=0` for paginated retrieval to structure your P&L (Profit and Loss) reports.
