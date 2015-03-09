# WebCheck

*Check your website, man!*

![WebCheck console](http://victorjonsson.se/webcheck.png)

## Installation

Since this gem isn't published you'll need to install it manually.

**1)** Clone the project

`$ git clone git@github.com:victorjonsson/webcheck.git`

**2)** Navigate to the directory in the console and install the gems using bundler ($ gem install bundler)

`$ bundle install`

**3)** Add the bin directory of webcheck to your $PATH and give the file bin/webcheck execution permission

First chmod the executable

`$ chmod +x bin/webcheck`

And then add the bin directory to your $PATH

`$ echo export PATH="/path/to/your/downloaded/webcheck/bin:$PATH"`

... or link to local bin directory


`$ ln -s /path/to/webcheck/bin/webcheck /usr/local/bin/webcheck`
