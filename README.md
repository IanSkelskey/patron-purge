# Patron Purge

This repository contains a collection of scripts for purging patron records from an Evergreen ILS database. The scripts are designed to be run on a Evergreen database server. The scripts are written in SQL and shell script.

## Purge Criteria

A patron record is eligible for purging if it meets the following criteria:

- No activity in the last 5 years
- No lost items
- No bills

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

![Bash](https://img.shields.io/badge/Bash-brightgreen.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-blue.svg?style=for-the-badge&logo=postgresql&logoColor=white)

### License

This project is licensed under the MIT License.

### Author

Ian Skelskey