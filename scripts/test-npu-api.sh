#!/bin/bash
# NPU API Verification Script
# Tests the local FastFlowLM server using an OpenAI-compatible JSON payload.

URL="http://127.0.0.1:8000/v1/chat/completions"

echo "Connecting to NPU Server at $URL..."

curl -N "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "lfm2:2.6b",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant running on a 51 TOPS Strix Halo NPU."
      },
      {
        "role": "user",
        "content": "Explain why NPU acceleration is superior to CPU for LLM inference."
      }
    ],
    "stream": true
  }'

echo -e "\n\nTest Complete."
