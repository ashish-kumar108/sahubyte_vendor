# Sahubyte Vendor

Service-provider Flutter application for receiving customer repair requests, accepting work and managing the on-site service lifecycle. It complements the Sahubyte User app as the operational side of the platform.

## Product flow

- Technician authentication and profile setup
- Incoming enquiry review and acceptance
- Skill and service-area management
- Assignment and job-status updates
- Job cards with diagnosis, work notes and required parts
- Image and document handling
- Technician ratings and completed-job history

## Engineering highlights

- MVVM-style separation across views, view models, repositories and network services
- Typed request and response models for REST workflows
- Reusable error handling and persistent sessions
- Responsive Flutter UI for Android, web and desktop targets
- Media selection and job-document workflows

## Tech stack

Flutter, Dart, REST APIs, HTTP, Shared Preferences, Image Picker, Google Fonts, URL Launcher and Open File.

## Related application

The customer booking workflow is available in [Sahubyte User](https://github.com/ashish-kumar108/sahubyte_user).

## Note

This repository demonstrates the Flutter client architecture and product workflow. A compatible backend service is required for live data.
