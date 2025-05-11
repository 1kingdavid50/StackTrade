import { describe, it, expect, beforeEach } from "vitest";

// Mocking a simple in-memory state to simulate contract storage
let contractState = {
  itemCounter: 1,
  exchangeFee: 3, // 3% fee
  exchangeVolume: 0,
  contentOfferings: {},
  traderMetrics: {},
  exchangeRecords: {},
  contentKeys: {}
};

// Helper functions to mimic contract behavior
const registerContent = (askingPrice, summary, contentType, accessToken, sender) => {
  if (askingPrice <= 0) return { error: "ERR_PRICE_INVALID" };
  if (!summary || !contentType || !accessToken) return { error: "ERR_INPUT_INVALID" };

  let itemId = contractState.itemCounter;
  contractState.contentOfferings[itemId] = {
    owner: sender,
    priceTag: askingPrice,
    contentSummary: summary,
    contentType: contentType,
    tradeable: true,
    creationBlock: 100 // Simulated block height
  };
  
  contractState.contentKeys[itemId] = { secureAccessToken: accessToken };
  contractState.itemCounter++;

  return { success: itemId };
};

const acquireContent = (itemId, buyer) => {
  const item = contractState.contentOfferings[itemId];
  if (!item) return { error: "ERR_ITEM_UNAVAILABLE" };
  if (!item.tradeable) return { error: "ERR_ITEM_UNAVAILABLE" };
  if (item.owner === buyer) return { error: "ERR_SELF_TRADE_BLOCKED" };

  let feeAmount = (item.priceTag * contractState.exchangeFee) / 100;
  let merchantShare = item.priceTag - feeAmount;

  contractState.exchangeRecords[buyer] = {
    itemId,
    timestamp: 100,
    cost: item.priceTag,
    merchant: item.owner
  };

  contractState.exchangeVolume++;
  return { success: true };
};

const retrieveAccessToken = (itemId, buyer) => {
  if (!contractState.exchangeRecords[buyer] || contractState.exchangeRecords[buyer].itemId !== itemId) {
    return { error: "ERR_UNAUTHORIZED" };
  }
  return { success: contractState.contentKeys[itemId].secureAccessToken };
};

describe("Digital Asset Exchange Smart Contract", () => {
  beforeEach(() => {
    // Reset contract state before each test
    contractState = {
      itemCounter: 1,
      exchangeFee: 3,
      exchangeVolume: 0,
      contentOfferings: {},
      traderMetrics: {},
      exchangeRecords: {},
      contentKeys: {}
    };
  });

  it("should register digital content", () => {
    const result = registerContent(100, "Test Content", "image", "secure-token-123", "user1");
    expect(result.success).toBe(1);
  });

  it("should prevent registration with invalid input", () => {
    const result = registerContent(0, "", "", "", "user1");
    expect(result.error).toBe("ERR_INPUT_INVALID");
  });

  it("should allow a user to acquire listed digital content", () => {
    registerContent(100, "Test Content", "image", "secure-token-123", "user1");
    const result = acquireContent(1, "user2");
    expect(result.success).toBe(true);
  });

  it("should prevent self-trade", () => {
    registerContent(100, "Test Content", "image", "secure-token-123", "user1");
    const result = acquireContent(1, "user1");
    expect(result.error).toBe("ERR_SELF_TRADE_BLOCKED");
  });

  it("should allow buyer to retrieve access token after purchase", () => {
    registerContent(100, "Test Content", "image", "secure-token-123", "user1");
    acquireContent(1, "user2");
    const result = retrieveAccessToken(1, "user2");
    expect(result.success).toBe("secure-token-123");
  });

  it("should prevent unauthorized access to content", () => {
    registerContent(100, "Test Content", "image", "secure-token-123", "user1");
    const result = retrieveAccessToken(1, "user3");
    expect(result.error).toBe("ERR_UNAUTHORIZED");
  });
});