# HighLevelBrowse

Given an LC Call Number, get a set of academic disciplines associated with it

## Usage

```ruby

use 'high_level_browse'

# Pull a new version of the raw data from the UM website,
# transform it into something that can be quickly searched,
# and save to the specified directory
hlb = HighLevelBrowse.fetch_and_save(dir: '/tmp')

# ...or just grab an already fetch_and_saved copy
hlb = HighLevelBrowse.load(dir: '/tmp')

# What HLB categories is an LC Call Number in?
hlb.topics 'hc 9112.2'
# => [["Social Sciences", "Economics"],
#     ["Social Sciences", "Social Sciences (General)"]]

# ... or use the shortcut syntax

hlb['NC1766 .U52 D733 2014']
# => [["Arts", "Art History"],
#    ["Arts", "Art and Design"],
#    ["Arts", "Film and Video Studies"]]

# You can also send more than one at a time

hlb.topics('E 99 .S2 Y67 1993', 'PS 3565 .R5734 F67 2015')
# => [["Humanities", "American Culture"],
#     ["Humanities", "United States History"],
#     ["Social Sciences", "Native American Studies"],
#     ["Social Sciences", "Archaeology"],
#     ["Humanities", "English Language and Literature"]]

```

There are also a couple command line applications for managing and querying the
data.

```bash

$> fetch_new_hlb

fetch_new_hlb -- get a new copy of the HLB ready for use by high_level_browse
and stick it in the given directory

   fetch_new_hlb <dir>

$> hlb

hlb -- get high level browse data for an LC call number

Example:
   hlb "qa 11.33 .C4 .H3"
   or do several at once
   hlb "PN 33.4" "AC 1122.3 .C22" ...


```

## Overview

The University of Michigan Library has for years maintained 
the [High Level Browse](https://www.lib.umich.edu/browse/categories/),
a mapping of call-number ranges to academic subjects. The entire 
data set is available as [1.8MB XML file](https://www.lib.umich.edu/browse/categories/xml.php)
for download.

This gem gives a relatively time-efficient way to get the set of disciplines associated
with the given callnumber or callnumbers as part of indexing MARC records into Solr. 
This mapping is used in many places in the University Library at the University of 
Michigan, including the 
[Mirlyn Catalog](https://mirlyn.lib.umich.edu/)
(exposed as "Academic Discipline" in the facets) and ejournals/databases (and even 
Librarians!) via the [Browse page](https://www.lib.umich.edu/browse). 
 
This categorization may be useful for clustering/faceting
in similar applications at other institutions. Note that the actual creation and 
maintenance of the call number ranges is done by subject specialist librarians and 
is out of scope for this gem.


## A warning about coverage

Note that not every possible valid callnumber will be necessarily be contained in any 
dicipline at all. Coverage is known to have some holes, and the ranges themselves 
sometimes cover essentially a single book in the umich collection.

Hence, this may or may not be useful at your insitution. You'll have to experiment.

## Installation

```bash
    gem 'high_level_browse'
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/high_level_browse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
