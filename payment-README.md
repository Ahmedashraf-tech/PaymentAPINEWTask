# Payment Mock Service

A Postman mock service for payment initiation with IBAN validation and three response scenarios.

---

## Project Structure

```
payment-mock/
├── PaymentMock.postman_collection.json   # Postman collection with all scenarios
├── newman-report.html                    # Newman HTML test report
└── README.md                             # This file
```

---

## Collection Import Instructions

1. Open **Postman**
2. Click **Import** (top left)
3. Select `PaymentMock.postman_collection.json`
4. The collection appears as **"Payment Mock Service"** in your sidebar

---

## Mock Server Setup Steps

### Step 1: Create Mock Server in Postman

1. In Postman, go to **Mock Servers** → **Create Mock Server**
2. Select **"Create a mock server from an existing collection"**
3. Choose **Payment Mock Service**
4. Name it: `Payment Mock`
5. Click **Create Mock Server**
6. Copy the generated **Mock Server URL** (e.g., `https://abc123.mock.pstmn.io`)

### Step 2: Set the Base URL Variable

1. In the collection, click **Variables**
2. Set `baseUrl` current value to your Mock Server URL:
   ```
   https://abc123.mock.pstmn.io
   ```

### Step 3: Configure Mock Responses

Postman Mock Server uses the **saved example responses** inside each request to determine what to return. These are already configured in the collection via the `X-Mock-Scenario` header:

| Header Value        | Triggered Response         |
|---------------------|---------------------------|
| `success`           | 201 Created               |
| `invalid-iban`      | 422 Unprocessable Entity  |
| `insufficient-funds`| 400 Bad Request           |

---

## Test Execution Commands

### Prerequisites

```bash
# Install Newman globally
npm install -g newman

# Install Newman HTML reporter
npm install -g newman-reporter-html
```

### Run All Tests

```bash
newman run PaymentMock.postman_collection.json \
  --env-var "baseUrl=https://your-mock-server.mock.pstmn.io"
```

### Run with HTML Report

```bash
newman run PaymentMock.postman_collection.json \
  --env-var "baseUrl=https://your-mock-server.mock.pstmn.io" \
  --reporters cli,html \
  --reporter-html-export newman-report.html
```

### Run a Single Scenario

```bash
# Run only Scenario 1 (Successful Payment)
newman run PaymentMock.postman_collection.json \
  --env-var "baseUrl=https://your-mock-server.mock.pstmn.io" \
  --folder "Scenario 1 - Successful Payment (Valid IBAN, Amount <= 1000)"
```

---

## API Reference

### Endpoint

```
POST /v1/payments
```

### Request Body

```json
{
  "instructedAmount": {
    "currency": "EUR",
    "amount": "150.75"
  },
  "debtorAccount": {
    "iban": "DE89370400440532013000"
  },
  "creditorAccount": {
    "iban": "DE89770400440532013000"
  },
  "creditorName": "Amazon EU",
  "remittanceInformationUnstructured": "Invoice #AMZ-2024-001"
}
```

---

## Validation Rules Summary

### IBAN Validation

| Rule | Detail |
|------|--------|
| **Regex Pattern** | `^[A-Z]{2}[0-9]{2}[A-Z0-9]{18}$` |
| **Total Length** | Exactly **22** characters |
| **Characters 1-2** | Uppercase letters only `[A-Z]` — country code |
| **Characters 3-4** | Digits only `[0-9]` — check digits |
| **Characters 5-22** | Uppercase alphanumeric `[A-Z0-9]` — BBAN |
| **Spaces** | NOT allowed |
| **Special characters** | NOT allowed (-, /, . etc.) |
| **Lowercase** | NOT allowed |

**Valid IBAN Examples:**

```
DE89370400440532013000   ✔  German IBAN
DE89770400440532013000   ✔  German IBAN
```

**Invalid IBAN Examples:**

```
DE123                    ✘  Too short (5 chars, need 22)
de89370400440532013000   ✘  Lowercase country code
DE89 3704 0044 0532 00   ✘  Contains spaces
DE89-3704-0044-0532013   ✘  Contains special characters
```

### Amount Validation

| Rule | Detail |
|------|--------|
| Amount **<= 1000** | → 201 Successful Payment |
| Amount **> 1000**  | → 400 Insufficient Funds |

---

## Response Scenarios

### Scenario 1 — Successful Payment `201 Created`
**Trigger:** Valid IBAN + Amount <= 1000

```json
{
  "transactionStatus": "RCVD",
  "paymentId": "PAY123456789",
  "transactionFeeIndicator": true,
  "_links": {
    "self": { "href": "/v1/payments/PAY123456789" },
    "status": { "href": "/v1/payments/PAY123456789/status" }
  }
}
```

### Scenario 2 — Invalid IBAN `422 Unprocessable Entity`
**Trigger:** IBAN doesn't match `^[A-Z]{2}[0-9]{2}[A-Z0-9]{18}$`

```json
{
  "type": "INVALID_IBAN_FORMAT",
  "title": "Invalid IBAN format",
  "status": 422,
  "detail": "The provided IBAN format is invalid",
  "validationRules": {
    "pattern": "2 uppercase letters + 2 digits + 18 alphanumeric characters",
    "totalLength": 22,
    "allowedCharacters": "A-Z, 0-9, no spaces or special characters"
  },
  "invalidFields": [
    {
      "field": "debtorAccount.iban",
      "reason": "Format validation failed",
      "providedValue": "DE123"
    }
  ]
}
```

### Scenario 3 — Insufficient Funds `400 Bad Request`
**Trigger:** Amount > 1000

```json
{
  "type": "INSUFFICIENT_FUNDS",
  "title": "Insufficient funds",
  "status": 400,
  "detail": "The debtor account has insufficient funds to execute the payment",
  "availableBalance": "850.00",
  "requestedAmount": "1500.75"
}
```

---

## Test Cases Coverage

| # | Scenario | IBAN | Amount | Expected Status |
|---|----------|------|--------|-----------------|
| 1 | Successful Payment | `DE89370400440532013000` ✔ | 150.75 | 201 |
| 2 | Invalid IBAN — too short | `DE123` ✘ | 150.75 | 422 |
| 3 | Insufficient Funds | `DE89370400440532013000` ✔ | 1500.75 | 400 |
| 4 | IBAN with spaces | `DE89 3704 0044...` ✘ | 150.75 | 422 |
| 5 | Lowercase IBAN | `de89370400440532013000` ✘ | 150.75 | 422 |

---

## Notes

- The mock server uses the `X-Mock-Scenario` request header to match the correct saved response example
- All IBAN validation logic is implemented in the Postman **Tests** tab using JavaScript
- Newman requires Node.js 14+ to run
