#!/bin/bash

# Push script for HR Brand Research Agent to GitHub

cd /Users/kseniaandreeva/Documents/hr_brand_agent_full

echo "🚀 Pushing HR Brand Research Agent to GitHub..."
echo ""

# Configure git (if not already done)
git config user.email "andreevaksan@gmail.com"
git config user.name "andks-me"

# Add remote (if not already done)
git remote add origin https://github.com/andks-me/HR-agent.git 2>/dev/null || echo "Remote already exists"

# Ensure we're on main branch
git branch -M main

# Push to GitHub
echo "⬆️  Uploading files..."
git push -u origin main

echo ""
echo "✅ Done!"
echo ""
echo "Your repository is at: https://github.com/andks-me/HR-agent"
echo ""
