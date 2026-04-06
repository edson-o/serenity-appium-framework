# serenity-appium-framework

This project is a mobile automation framework built using Serenity BDD and Appium.

## Overview
The framework follows the Screenplay pattern and is designed for scalable and maintainable mobile test automation.

## Tech Stack
- Java
- Serenity BDD
- Appium
- Cucumber
- Gradle

## Features
- BDD with Cucumber
- Screenplay design pattern
- Android automation support
- Integration with CI/CD pipelines
- Detailed reporting with Serenity

## How to Run
1. Configure the desired environment in serenity.conf
2. Connect a real device or emulator
3. Run the tests using:
   ./gradlew clean test
4. Generate reports:
   ./gradlew aggregate

## Notes
- Ensure Appium server is running before execution
- Update device capabilities as needed