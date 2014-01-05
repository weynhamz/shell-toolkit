bashTest
========

A Bash testing framework using TAP protocol.

How to use
----------

bashTest depends on my aother project [bashLib][] which is a collection of
commonly used Bash functions. Just clone bashLib to one of the following
locations, bashTest will try to fiind them in the following order.

    1. PROJECT_ROOT/bundles/bashLib/src/bashLib"
    2. PROJECT_ROOT/../bashLib/src/bashLib"
    3. /usr/share/lib/bashLib/bashLib"


[bashLib]: https://github.com/techlivezheng/bashLib

APIs
----

The symtax is pretty much like many other *unit testing frameworks.

### Functions

* `_set_up`

    Called at the beginning every time a test runs to set up necessary test
    facility.

* `_tear_down`

    Called at the end every time a test runs to clean up the test facility for
    next run.

* `_test_run $msg $test`

    Runs a actual test. First argument is the msg that will be print to the
    stdout for test harness to process. The second is the actual test content
    to run, quotes must be carefully handled.

* `_test_done`

    Called after all tests finished, the main purpose is to print the test
    plan.

### Assertions

* `_test_expect_missing "$path"`

    Fail if `$path` exists

* `_test_expect_symlink "$target" "$source"`

    Fail if `$target` is not symlinked to `$source`

* `_test_expect_directory "$path"`

    Fail if `$path` is not a directory

* `_test_expect_expr_true "$expr"`

    Fail if the result of evaluating `$expr` is false

* `_test_expect_expr_false "$expr"`

    Fail if the result of evaluating `$expr` is true

* `_test_expect_expr_match "$expr1" "$expr2"`

    Fail if `$expr1` does not match `$expr2`

### Env-Variables

* `TEST_COUNT`

    Counter of tests that have been executed.

* `TEST_FIELD`

    A directory where each test will be run, and is unique for each test.

Examples
--------

For an example using this framework, take a look at a script called [dotploy][]
I wrote to manage and deploy the dot files.

[dotploy]: https://github.com/techlivezheng/dotploy/blob/master/tests/test-dotploy.sh


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/techlivezheng/bashtest/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

