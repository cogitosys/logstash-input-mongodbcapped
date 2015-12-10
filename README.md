# Logstash Mongodb Capped Collection Input Plugin

This is an input plugin for [Logstash](https://github.com/elastic/logstash) to read from a mongodb capped collection.

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Example Usage

```
input {
    mongodbcapped {
        uri => "mongodb://localhost/somedb?ssl=true"
        collections => ["my_capped_colleciton", "some_other_db/some_collection"]
    }
}
```

## Documentation

Logstash provides infrastructure to automatically generate documentation for this plugin. We use the asciidoc format to write documentation so any comments in the source code will be first converted into asciidoc and then into html. All plugin documentation are placed under one [central location](http://www.elastic.co/guide/en/logstash/current/).

- For formatting code or config example, you can use the asciidoc `[source,ruby]` directive
- For more asciidoc formatting tips, see the excellent reference here https://github.com/elastic/docs#asciidoc-guide

## Known issues

No attempt is made to handle broken connections. If your mongo goes down while running this plugin, it may well crash logstash. Logstash in general is not a robust system, so that's not a big worry.

## Roadmap

Here's my shortlist of things I'd like to add eventually:

- [ ] polling input -> useful for scraping systemStats(), db.stats(), etc
- [ ] start_from support -> to skip over existing messages in a capped collection
- [x] collection as a string or an array in config
- [ ] wildcard support for collections
- [ ] proper error recovery, retry timing and backoff (needs input from elastic team about philosophy)

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Local development

You'll need JRuby installed with Bundler. `bundle install` and `bundle exec rspec` to get started.

#### 1.1 Running in Logstash

Either add the gem by path to the Gemfile, and `bin/plugin install --no-verify`, or build the gem and install with `bin/plugin install /path/to/logstash-input-mongodbcapped.gem`

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
