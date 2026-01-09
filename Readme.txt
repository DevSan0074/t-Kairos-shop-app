flutter run -d chrome
flutter clean
flutter pub get
flutter run



# === START: COPY EVERYTHING BELOW THIS LINE ===

# Step 1: Initialize a new Git repository in your folder
git init

# Step 2: Add all your files to be tracked by Git
git add .

# Step 3: Save a snapshot of your files with a message
git commit -m "Initial commit of T Kairos project"

# Step 4: Rename the default branch to 'main'
git branch -M main

# Step 5: Connect your local folder to your GitHub repository
git remote add origin https://github.com/DevSan0074/t-Kairos-shop-app

# Step 6: Forcefully upload (push) all your files to GitHub
git push -f origin main

# === END: YOU ARE FINISHED AFTER THIS COMMAND ===