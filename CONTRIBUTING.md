# Contributing to Steps Reminder Widget

Got an idea for an improvement or found a bug? I’d love your help!

## How to Contribute

### 🐛 Reporting Issues
If you found a bug or have a suggestion, please open a new Issue in the repository.  
Please include:
* **Device model** (e.g., Fenix 7 Pro)
* **Firmware version**
* **Steps to reproduce** the issue
* **Expected vs actual** behavior
* **Screenshots** if relevant

### 💻 Pull Requests
Want to fix code or add a feature?

1.  **Fork** the repository
2.  **Create a new branch** for your change:
    ```bash
    git checkout -b feature/your-feature-name
    ```
3.  **Make your changes**
4.  **Run tests** (if applicable)
5.  **Commit** with a clear message:
    ```bash
    git commit -m "Add: description of your changes"
    ```
6.  **Push** to your fork:
    ```bash
    git push origin feature/your-feature-name
    ```
7.  **Send a Pull Request** with an explanation of the change.

---

### ⚠️ API Compatibility & Crash Prevention
> **Important:** To prevent crashes on older devices, you must explicitly add a check for any new feature. Use an `if` statement with the `has` operator to verify the feature exists before calling it. If a feature is not supported on older devices, ensure the code handles it gracefully without crashing.

---

### 🌍 Adding Device Support
Want to add support for another watch?

1.  Edit `manifest.xml`
2.  Add the product ID:
    ```xml
    <iq:product id="your-device-id"/>
    ```
3.  Verify the code works on the device.
4.  Submit a PR.

### 📝 Code Style Guidelines
* **Indentation:** Use 4 spaces.
* **Comments:** In English.
* **Variable names:** English, descriptive.
* **Function names:** `camelCase`.
* **Class names:** `PascalCase`.

### 🧪 Testing
Before submitting a PR, please:
* Test on the **simulator**.
* If possible, test on a **physical device**.
* Ensure **settings** are working.
* Check both languages (**Hebrew and English**).

### 🗣️ Language
All technical communication (Code comments, Commit messages, Issue discussions, PR descriptions) should be in **English**.

### 📦 What We're Looking For
* Support for more Garmin devices.
* Additional notification options.
* More flexible scheduling options.
* UI improvements & Battery optimization.

### ⚖️ License
By submitting a contribution, you agree that your code will be under the **CC BY-NC 4.0** license.

---

**🙏 Thank You!** Every contribution, small or large, is greatly appreciated!  
Questions? Open an issue or discussion!