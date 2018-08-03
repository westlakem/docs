module Jekyll

    require 'html/pipeline'
    require "liquid"

    class IncludeFilter < HTML::Pipeline::TextFilter
      def initialize(text, context = nil, result = nil)
        super text, context, result
        @site = Jekyll::JekyllSiteGenerator.site
      end

      def call
        new_text = @text.gsub(/!!include\(([^\)]+)\)/) do
          file_path = $1
          render_include(file_path)
        end

        def render_include(file_path)
            template_content = File.read(file_path)

            page = Page.new(@site, @site.source, '', file_path)
            page.content = template_content
            page.render(Hash.new, @site.site_payload)

            page.output
        end
        if new_text.include? "itemtype"
            puts "------------------------itemtype 32126543-----------------------"
            puts new_text
            puts new_text.split('-')[0]
            new_text = new_text.split('-')[0]
            puts "-----------------------------------------------"
            puts new_text
        end
        new_text
      end
    end

    class RootRelativeFilter < HTML::Pipeline::Filter

        def call
            doc.search('a').each do |a|
                next if a['href'].nil?

                href = a['href'].strip

                if href.start_with? '/'
                    a['href'] = context[:baseurl] +  href
                end
                puts "-------------------URLhrefcontext-------------------------";
                puts "--------------------------------------------";
                puts "--------------------------------------------";
                puts "--------------------------------------------";
                puts "testhrefcontext"
                puts href
                puts "--------------------------------------------";
                puts "--------------------------------------------";
                puts "--------------------------------------------";
                # Transform article .md links to .html
                if /\.md(#.*?)?$/.match(href)
                    # Leave external(absolute) links alone
                    unless /^(https?:)?\/\//.match(href)
                      a['href'] = href.gsub(/\.md(#.*?)?$/, ".html#{$1}")
                    end
                end
            end

            doc.search('img').each do |img|
                next if img['src'].nil?

                src = img['src'].strip

                if src.start_with? '/'
                    img['src'] = context[:baseurl] + src
                end
            end

            doc
        end

    end

    class NSCookbookFilter < HTML::Pipeline::Filter

        def call
            doc.search('a').each do |a|
                next if a['href'].nil?

                href = a['href'].strip

                if href.include? "NS_COOKBOOK"
                    a['href'] = href.sub(/NS_COOKBOOK\/?/, context[:nscookbookurl])
                end
            end

            doc
        end

    end

    class ApiHeaderIdFilter < HTML::Pipeline::Filter

        def call

            doc.css('h2').each do |node|
                text = node.text
               
                if text.include? "itemtype"
                    puts "------------------------itemtype 3212-----------------------"
                    puts text
                    text = text.split('-')[0]
                    puts "-----------------------------------------------"
                    puts text
                end
                next unless text =~ /^Configuration|Events|Properties|Methods|Class Methods|Fields$/

                prefix = text.downcase.gsub(' ', '-')

                node = node.next_element

                until node.nil?
                    break if node.name == 'h2'

                    if node.name == 'h3'
                        id = node.text
                        id.gsub!(/ .*/, '')
                        id.gsub!(/`[^`]*`/, '')
                        id.gsub!(/\\/,'')
                        id.gsub!(/\*[^*]*\*/, '')
                        node['id'] = "#{prefix}-#{id}"
                    end

                    node = node.next_element
                end

            end

            doc
        end

    end

    # based on https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/toc_filter.rb
    class HeaderLinkFilter < HTML::Pipeline::Filter

        @@punctuation_regexp = RUBY_VERSION > "1.9" ? /[^\p{Word}\- ]/u : /[^\w\- ]/

        def call

            doc.css('h1, h2, h3').each do |node|

                id = node['id']
                attrb = ''
                attrval = ''
                unless id
                    id=""
                    newid = node.text.downcase
                    puts "-------------------URLidsplit-------------------------";
                    puts "--------------------------------------------";
                    puts "--------------------------------------------";
                    puts "--------------------------------------------";
                    puts "testid"
                    if newid.include? "itemtype"
                        # puts "test include"
                        vals = newid.split('-')
                        # puts "First"
                        # puts vals[0]
                        # puts "Second"
                        # puts vals[1]
                        id = vals[0]
                        itemtype = vals[1]
                        itemtype.gsub!(' ', '')
                        # puts "testtest puts out"
                        # puts itemtype.split('~')[0]
                        # puts itemtype.split('~')[1]
                        attrb = itemtype.split('~')[0]
                        attrval = itemtype.split('~')[1]
                        puts 'test include attr2'
                        puts attrb
                        puts attrval
                    else
                        id = newid
                    end
                    
                    puts "--------------------------------------------";
                    puts "--------------------------------------------";
                    puts "--------------------------------------------";
                    id.gsub!(@@punctuation_regexp, '') # remove punctuation
                    id.gsub!(' ', '-') # replace spaces with dash
                end

                node['id'] = id

                a = Nokogiri::XML::Node.new('a', doc)
                
                a['href'] = "##{id}"
                unless attrb.empty?
                    a[attrb] = "http://schema.org/#{attrval}"
                end
                a.children = node.children
                node.add_child a
            end

            doc
        end
    end

    class Converters::Markdown::MarkdownProcessor
        def initialize(config)
            @config = config

            context = {
                :gfm => false,
                :baseurl => @config['baseurl'],
                :nscookbookurl => @config['nscookbookurl']
            }

            @pipeline = HTML::Pipeline.new [
                IncludeFilter,
                HTML::Pipeline::MarkdownFilter,
                RootRelativeFilter,
                NSCookbookFilter,
                ApiHeaderIdFilter,
                HeaderLinkFilter
            ], context

        end

        def convert(content)
            @pipeline.call(content)[:output].to_s
        end
    end

end
