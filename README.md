# Womath

A simple tool to retrieve personal details from GitHub from commits

## Installation
Install ruby and bundler, run `bundle install`. Create a MySQL-database, copy `config.example.rb` to `config.rb` and fill in the details.

## Usage
`ruby rate_limit.rb` gives some insight in how many requests to the GitHub API you still have left and when the counter will reset. `ruby harvest.rb` gathers the personal information of all contributors to a repository on GitHub. It takes the canonical name of the repository as a parameter (for example `ruby harvest.rb jakobbuis/womath`). `ruby determine_company.rb` processes all found entries and determines the company name using various methods. Both files accept -h or --help to display basic instructions and -v to generate more debug data.

## License
Copyright Jakob Buis 2014-2015. This version of the code is distributed under the GNU GPL v3 license, the full text of which is included in the LICENSE file.
