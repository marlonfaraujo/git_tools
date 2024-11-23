### Git Tools

This repository contains a collection of scripts for automating and maintaining Git repositories.
You will find tools written in Bash, Python, and other languages to help with tasks such as repository cleanup, migration, cloning, and maintenance.

The goal is to simplify repetitive operations and provide ready-to-use utilities for developers and DevOps engineers.

---

### Prerequisites

- **Git** installed ([download here](https://git-scm.com/))
- **Linux**, **WSL (Windows Subsystem for Linux)**, or a Bash-compatible terminal on Windows (such as Git Bash)
- **Python** installed ([download here](https://www.python.org/downloads/))

---

## Clone this repository

   ```bash
   git clone https://github.com/marlonfaraujo/git_tools.git
   cd git_tools
   ```

## Migrate repository script

Bash script that allows you to migrate a complete Git repository (including history, branches and tags) to a new remote repository.

1. Make the script executable:

  ```bash
   chmod +x migrate-repo.sh
   ```

2. Run the script with parameters:

  ```bash
   ./migrate-repo.sh <source_repository_url> <destination_repository_url> --checkout
   ```
   