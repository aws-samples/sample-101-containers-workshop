# AWS 101 - Containers Workshop

> For the complete workshop instructions and guided tutorials, visit [AWS 101 Containers Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/52e6d7a4-b24a-43cc-90cc-82920d6988f0/en-US).

This repository contains the source code, infrastructure templates, and supporting resources for the AWS 101 Containers Workshop - a hands-on learning experience for containerizing applications on AWS.

## Repository Structure

```
.
├── app-ec2/                          # Original monolithic Python Flask application
│   ├── app.py                        # Main Flask application with wildlife tracking
│   ├── templates/                    # HTML templates for web interface
│   └── static/                       # Static assets (images, CSS)
├── container-app/                    # Containerized microservices version
│   ├── frontend/                     # Web UI service (Flask + templates)
│   ├── dataapi/                      # REST API service for data access
│   ├── media/                        # Image upload and storage service
│   ├── alerts/                       # GPS tracking and alerts service
│   └── datadb/                       # MongoDB database container
├── terraform-broken/                 # Intentionally broken Terraform for learning
├── terraform-dev/                    # Working Terraform modules and configurations
│   └── modules/                      # Reusable Terraform modules
├── terraform-live/                   # GitOps deployment directory for Terraform code
└── workshop/                         # CloudFormation and setup scripts
    ├── AWS102.yml                    # CloudFormation template to setup workshop in your own AWS account
    ├── devbox-setup.sh               # Development environment setup script
    ├── workshop-helper.sh            # Automation and helper script
    └── cleanupscript.py              # Resource cleanup automation scipt
```

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/aws-samples/sample-101-containers-workshop.git
   cd sample-101-containers-workshop
   ```

2. **Deploy the workshop environment:**
   ```bash
   aws cloudformation deploy \
     --template-file workshop/AWS102.yml \
     --stack-name aws102 \
     --capabilities CAPABILITY_NAMED_IAM
   ```

3. **Follow the workshop instructions:**
   Visit the [AWS 101 Containers Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/52e6d7a4-b24a-43cc-90cc-82920d6988f0/en-US) to run the workshop.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
