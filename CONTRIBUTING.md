# Contributing to the Hyperledger Lab Perun

Want to contribute? That's great! Any contribution is welcome, e.g.
documentation, bug reports, feature request, issues, blog posts,
tutorials, feature implementations, etc. You can contribute code or
documentation through the standard GitHub pull request model. For large
contributions we do encourage you to file a ticket in the GitHub issue
tracking system prior to any development to coordinate with the Perun
development team early in the process. Coordinating up front helps to
avoid frustration later on.

*Note that this repository only contains the documentation of the Perun
project. For issues / pull requests related to source code please refer to the
[perun-node](https://github.com/hyperledger-labs/perun-node) repository.*

## Contribution Guideline

* We use the GitHub [issue
  tracker](https://github.com/hyperledger-labs/perun-doc/issues) and
  the [github-flow](http://scottchacon.com/2011/08/31/github-flow.html)
  branching model for perun-doc.

* When you want to submit a patch to any Hyperledger Labs project, you
  must [sign your commits](#sign-your-work).

* Your contribution must be licensed under the CC-BY-4.0 license, the
  license used by this project.

* When submitting a pull-request to the project, please note / ensure
  the following:
    1. Follow these [guidelines](https://chris.beams.io/posts/git-commit/) on
       how to write a good **commit** message. If available, include the
       ticket number. And don't forget the [Signed-Off-By](#sign-your-work)
       line.
    2. Create a pull request against the master branch.

## Legal stuff

### Sign your work

This project tracks patch provenance and licensing using the Developer
Certificate of Origin and Signed-off-by tags initially developed by
the Linux kernel project.

```text
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

With the sign-off in a commit message you certify that you authored the patch
or otherwise have the right to submit it under an open source license. The
procedure is simple: To certify above Developer's Certificate of Origin 1.1 for your contribution just append a line

```text
Signed-off-by: Random J Developer <random@developer.example.org>
```

to every commit message using your real name or your pseudonym and a valid
email address.

If you have set your `user.name` and `user.email` git configs you can
automatically sign the commit by running the git-commit command with the `-s`
option.  There may be multiple sign-offs if more than one developer was
involved in authoring the contribution.

For a more detailed description of this procedure, please see
[SubmittingPatches][] which was extracted from the Linux kernel project, and
which is stored in an external repository.

### Individual vs. Corporate Contributors

Often employers or academic institution have ownership over code that is
written in certain circumstances, so please do due diligence to ensure that
you have the right to submit the code.

If you are a developer who is authorized to contribute to Perun on behalf of
your employer, then please use your corporate email address in the
Signed-off-by tag. Otherwise please use a personal email address.

[SubmittingPatches]:
https://github.com/wking/signed-off-by/blob/7d71be37194df05c349157a2161c7534feaf86a4/Documentation/SubmittingPatches
