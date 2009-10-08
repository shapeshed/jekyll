require 'rubygems'
require 'sequel'
require 'fileutils'

# NOTE: This converter requires Sequel and the MySQL gems.
# The MySQL gem can be difficult to install on OS X. Once you have MySQL
# installed, running the following commands should work:
# $ sudo gem install sequel
# $ sudo gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config


module Jekyll
  module ExpressionEngine

    # Reads a MySQL database via Sequel and creates a post file for each
    # post in wp_posts that has post_status = 'publish'.
    # This restriction is made because 'draft' posts are not guaranteed to
    # have valid dates.
    QUERY = "SELECT t.title, t.entry_id, t.url_title, t.entry_date, d.field_id_1, d.field_id_2
        FROM exp_weblog_titles as t 
        LEFT JOIN exp_weblog_data as d
        ON d.entry_id = t.entry_id
        WHERE t.status = 'Open'
        AND t.weblog_id = '1'"
        


    def self.process(dbname, user, pass, host = 'localhost')
      db = Sequel.mysql(dbname, :user => user, :password => pass, :host => host)

      FileUtils.mkdir_p "_posts"

      db[QUERY].each do |post|
        
        post_categories = Array.new
        jekyll_categories = ""
        
        categories = db["SELECT c.cat_name FROM exp_category_posts as p
        LEFT JOIN exp_categories as c
        ON p.cat_id = c.cat_id
        WHERE p.entry_id = #{post[:entry_id]}"]
        

        
        categories.each do |category|
          post_categories << category[:cat_name]
        end
        
        post_categories.each do |post_category|
          jekyll_categories << post_category
        end
        
        # Get required fields and construct Jekyll compatible name
        title = post[:title]
        slug = post[:url_title]
        date = Time.at(post[:entry_date])
        content = post[:field_id_2]
        name = "%02d-%02d-%02d-%s.markdown" % [date.year, date.month, date.day,
                                               slug]

        # Get the relevant fields as a hash, delete empty fields and convert
        # to YAML for the header
        data = {
           'layout' => 'post',
           'title' => title.to_s,
           'categories' => jekyll_categories,
           'excerpt' => post[:field_id_1].to_s,
         }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

        # Write out the data and content to file
        File.open("_posts/#{name}", "w") do |f|
          f.puts data
          f.puts "---"
          f.puts content
        end
      end

    end
  end
end
