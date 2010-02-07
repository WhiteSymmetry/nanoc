# encoding: utf-8

module Nanoc3::CLI::Commands

  class CreateSite < Cri::Command

    DEFAULT_RULES = <<EOS
#!/usr/bin/env ruby

# A few helpful tips about the Rules file:
#
# * The order of rules is important: for each item, only the first matching
#   rule is applied.
#
# * Item identifiers start and end with a slash (e.g. “/about/” for the file
#   “content/about.html”). To select all children, grandchildren, … of an
#   item, use the pattern “/about/*/”; “/about/*” will also select the parent,
#   because “*” matches zero or more characters.

compile '/stylesheet/' do
  # don’t filter or layout
end

compile '*' do
  filter :erb
  layout 'default'
end

route '/stylesheet/' do
  '/style.css'
end

route '*' do
  item.identifier + 'index.html'
end

layout '*', :erb
EOS

    DEFAULT_ITEM = <<EOS
<h1>A Brand New nanoc Site</h1>

<p>You’ve just created a new nanoc site. The page you are looking at right now is the home page for your site (and it’s probably the only page).</p>

<p>To get started, consider replacing this default homepage with your own customized homepage. Some pointers on how to do so:</p>

<ul>
  <li><p><strong>Change this page’s content</strong> by editing “content.html” file in the “content” directory. This is the actual page content, and therefore doesn’t include the header, sidebar or style information (those are part of the layout).</p></li>
  <li><p><strong>Change the layout</strong>, which is the “default.txt” file in the “layouts/default” directory, and create something unique (and hopefully less bland).</p></li>
</ul>

<p>If you need any help with customizing your nanoc web site, be sure to check out the documentation (see sidebar), and be sure to subscribe to the discussion group (also see sidebar). Enjoy!</p>
EOS

    DEFAULT_STYLESHEET = <<EOS
* {
  margin: 0;
  padding: 0;

  font-family: Georgia, Palatino, Times, 'Times New Roman', sans-serif;
}

body {
  background: #fff;
}

a {
  text-decoration: none;
}

a:link,
a:visited {
  color: #f30;
}

a:hover {
  color: #f90;
}

#main {
  position: absolute;

  top: 40px;
  left: 280px;

  width: 500px;
}

#main h1 {
  font-size: 40px;
  font-weight: normal;

  line-height: 40px;

  letter-spacing: -1px;
}

#main p {
  margin: 20px 0;
  
  font-size: 15px;
  
  line-height: 20px;
}

#main ul {
  margin: 20px;
}

#main li {
  list-style-type: square;

  font-size: 15px;
  
  line-height: 20px;
}

#sidebar {
  position: absolute;

  top: 40px;
  left: 20px;
  width: 200px;

  padding: 20px 20px 0 0;

  border-right: 1px solid #ccc;

  text-align: right;
}

#sidebar h2 {
  text-transform: uppercase;

  font-size: 13px;

  color: #333;

  letter-spacing: 1px;

  line-height: 20px;
}

#sidebar ul {
  list-style-type: none;

  margin: 20px 0;
}

#sidebar li {
  font-size: 14px;

  line-height: 20px;
}
EOS

    DEFAULT_LAYOUT = <<EOS
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>A Brand New nanoc Site - <%= @item[:title] %></title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <link rel="stylesheet" type="text/css" href="/style.css" media="screen">
    <meta name="generator" content="nanoc #{Nanoc3::VERSION}">
  </head>
  <body>
    <div id="main">
<%= yield %>
    </div>
    <div id="sidebar">
      <h2>Documentation</h2>
      <ul>
        <li><a href="http://nanoc.stoneship.org/tutorial/">Tutorial</a></li>
        <li><a href="http://nanoc.stoneship.org/manual/">Manual</a></li>
      </ul>
      <h2>Community</h2>
      <ul>
        <li><a href="http://groups.google.com/group/nanoc/">Discussion Group</a></li>
        <li><a href="http://groups.google.com/group/nanoc-es/">Spanish Discussion Group</a></li>
        <li><a href="http://projects.stoneship.org/trac/nanoc/">Wiki</a></li>
      </ul>
    </div>
  </body>
</html>
EOS

    def name
      'create_site'
    end

    def aliases
      [ 'cs' ]
    end

    def short_desc
      'create a site'
    end

    def long_desc
      'Create a new site at the given path. The site will use the ' +
      'filesystem_compact data source by default, but this can be ' +
      'changed using the --datasource commandline option.'
    end

    def usage
      "nanoc3 create_site [options] path"
    end

    def option_definitions
      [
        # --datasource
        {
          :long => 'datasource', :short => 'd', :argument => :required,
          :desc => 'specify the data source for the new site'
        }
      ]
    end

    def run(options, arguments)
      # Check arguments
      if arguments.length != 1
        $stderr.puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments and options
      path        = arguments[0]
      data_source = options[:datasource] || 'filesystem_compact'

      # Check whether site exists
      if File.exist?(path)
        $stderr.puts "A site at '#{path}' already exists."
        exit 1
      end

      # Check whether data source exists
      if Nanoc3::DataSource.named(data_source).nil?
        $stderr.puts "Unrecognised data source: #{data_source}"
        exit 1
      end

      # Setup notifications
      Nanoc3::NotificationCenter.on(:file_created) do |file_path|
        Nanoc3::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Build entire site
      FileUtils.mkdir_p(path)
      FileUtils.cd(File.join(path)) do
        site_create_minimal(data_source)
        site_setup
        site_populate
      end

      puts "Created a blank nanoc site at '#{path}'. Enjoy!"
    end

  protected

    # Creates a configuration file and a output directory for this site, as
    # well as a rakefile that loads the standard nanoc tasks.
    def site_create_minimal(data_source)
      # Create output
      FileUtils.mkdir_p('output')

      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write(YAML.dump(
          'output_dir' => 'output',
          'data_sources' => [
            {
              'type'         => data_source,
              'items_root'   => '/',
              'layouts_root' => '/'
            }
          ]
        ))
      end
      Nanoc3::NotificationCenter.post(:file_created, 'config.yaml')

      # Create rakefile
      File.open('Rakefile', 'w') do |io|
        io.write "require 'nanoc3/tasks'"
      end
      Nanoc3::NotificationCenter.post(:file_created, 'Rakefile')

      # Create rules
      File.open('Rules', 'w') do |io|
        io.write DEFAULT_RULES
      end
      Nanoc3::NotificationCenter.post(:file_created, 'Rules')
    end

    # Sets up the site's data source, i.e. creates the bare essentials for
    # this data source to work.
    def site_setup
      # Get site
      site = Nanoc3::Site.new('.')

      # Set up data sources
      site.data_sources.each do |data_source|
        data_source.loading { data_source.setup }
      end
    end

    # Populates the site with some initial data, such as a root item, a
    # default layout, and so on.
    def site_populate
      # Get site
      site = Nanoc3::Site.new('.')
      data_source = site.data_sources[0]

      # Create home page
      data_source.create_item(
        DEFAULT_ITEM,
        { :title => "Home" },
        '/'
      )

      # Create stylesheet
      # FIXME give it a .css extension
      data_source.create_item(
        DEFAULT_STYLESHEET,
        {},
        '/stylesheet/'
      )

      # Create layout
      data_source.create_layout(
        DEFAULT_LAYOUT,
        {},
        '/default/'
      )

      # Create code
      FileUtils.mkdir_p('lib')
      File.open('lib/default.rb', 'w') do |io|
        io.write "\# All files in the 'lib' directory will be loaded\n"
        io.write "\# before nanoc starts compiling.\n"
      end
    end

  end

end
