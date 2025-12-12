#!/bin/bash

# Script to split the monorepo into separate frontend and backend repositories

echo "Splitting Photomi monorepo into separate repositories..."

# Create directories for the split repositories
mkdir -p ../photomi-backend ../photomi-frontend

# Copy backend files
echo "Copying backend files..."
cp -r backend/photomi/* ../photomi-backend/
cp .gitignore ../photomi-backend/
cp .gitattributes ../photomi-backend/
cp LICENSE ../photomi-backend/

# Copy frontend files
echo "Copying frontend files..."
cp -r frontend/photomi/* ../photomi-frontend/
cp .gitignore ../photomi-frontend/
cp .gitattributes ../photomi-frontend/
cp LICENSE ../photomi-frontend/

echo "Repository split complete!"
echo ""
echo "Next steps:"
echo "1. Initialize git in each new repository:"
echo "   cd ../photomi-backend && git init"
echo "   cd ../photomi-frontend && git init"
echo ""
echo "2. Add and commit files:"
echo "   cd ../photomi-backend && git add . && git commit -m \"Initial commit\""
echo "   cd ../photomi-frontend && git add . && git commit -m \"Initial commit\""
echo ""
echo "3. Create new repositories on GitHub/GitLab and push:"
echo "   cd ../photomi-backend && git remote add origin <backend-repo-url> && git push -u origin master"
echo "   cd ../photomi-frontend && git remote add origin <frontend-repo-url> && git push -u origin master"