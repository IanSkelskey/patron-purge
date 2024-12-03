# Parallel Purge Process

This repository contains a script to perform parallel purging of database records.

## Script: Create Buckets

### Description

`scripts\create_buckets.sh` is a shell script designed to create buckets for purge-eligible patron records. A bucket is made for each library in the consortium. This is to accomodate library staff reviewing the records before they are purged. Staff may remove records from the bucket if they are not ready to be purged. The actual purging of records is done from the buckets.

### Features

- Parallel execution of purge operations

### Usage

1. **Clone the repository:**
    ```sh
    git clone git@github.com:IanSkelskey/patron-purge.git
    cd scripts
    ```

2. **Make the script executable:**
    ```sh
    chmod +x create_buckets.sh
    ```

3. **Run the script:**
    ```sh
    ./create_buckets.sh <db_name>
    ```

### Example

```sh
./create_buckets.sh "eg_spork1"
```

### Requirements

- Bash shell
- PostgreSQL client

### License

This project is licensed under the MIT License.

### Author

Ian Skelskey