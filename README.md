# Parallel Purge Process

This repository contains a script to perform parallel purging of database records.

## Script: `parallel_purge_process.sh`

### Description

`parallel_purge_process.sh` is a shell script designed to purge database records in parallel, improving the efficiency and speed of the purge process.

### Features

- Parallel execution of purge operations

### Usage

1. **Clone the repository:**
    ```sh
    git clone <repository_url>
    cd parallel_purge_process
    ```

2. **Make the script executable:**
    ```sh
    chmod +x parallel_purge_process.sh
    ```

3. **Run the script:**
    ```sh
    ./parallel_purge_process.sh <db_name>
    ```

### Example

```sh
./parallel_purge_process.sh "eg_spork1"
```

### Requirements

- Bash shell
- PostgreSQL client

### License

This project is licensed under the MIT License.

### Author

Ian Skelskey