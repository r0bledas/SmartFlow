#!/bin/sh

# This script helps configure the SmartFlow app to support the 'smartflow://' URL scheme
# It prints instructions on how to add the URL scheme to your project settings

echo "=================================================="
echo "SmartFlow URL Scheme Setup Guide"
echo "=================================================="
echo ""
echo "To enable the 'smartflow://' URL scheme in your app, please follow these steps:"
echo ""
echo "1. Open your SmartFlow.xcodeproj in Xcode"
echo "2. Select the SmartFlow target"
echo "3. Go to the 'Info' tab"
echo "4. Expand the 'URL Types' section"
echo "5. Click the '+' button to add a new URL type"
echo "6. Configure the URL type as follows:"
echo "   - Identifier: com.Robledas.SmartFlow"
echo "   - URL Schemes: smartflow (just type this word)"
echo "   - Role: Editor"
echo "7. Click outside the URL type editor to save"
echo "8. Build and run your app"
echo ""
echo "After following these steps, your app will be able to handle URLs like 'smartflow://reset'"
echo "You've already added the code to handle these URLs in your SmartFlowApp.swift file."
echo ""
echo "=================================================="