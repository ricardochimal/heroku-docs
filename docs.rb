require 'rubygems'
require 'sinatra'
require 'rdiscount'
require 'vendor/heroku_header'

set :app_file, __FILE__

configure do
	HerokuHeader.fetch_latest('docs')
end

not_found do
	erb :not_found
end

get '/README' do
	render_topic './README'
end

get '/' do
	cache_long
	render_topic 'index'
end

get '/:topic' do
	cache_long
	render_topic params[:topic]
end

get '/css/docs.css' do
	cache_long
	content_type 'text/css'
	erb :css, :layout => false
end

before do
	@asset_host = ENV['ASSET_HOST']
end

helpers do
	def render_topic(topic)
		source = File.read(topic_file(topic))
		@content = markdown(source)
		@title, @content = title(@content)
		@toc, @content = toc(@content)
		@topic = topic
		erb :topic
	rescue Errno::ENOENT
		status 404
	end

	def cache_long
		response['Cache-Control'] = "public, max-age=#{60 * 60}" unless development?
	end

	def notes(source)
		source.gsub(/NOTE: (.*)/, '<table class="note"><td class="icon"></td><td class="content">\\1</td></table>')
	end

	def markdown(source)
		RDiscount.new(notes(source), :smart).to_html
	end

	def topic_file(topic)
		if topic.include?('/')
			topic
		else
			"#{options.root}/docs/#{topic}.txt"
		end
	end

	def title(content)
		title = content.match(/<h1>(.*)<\/h1>/)[1]
		content_minus_title = content.gsub(/<h1>.*<\/h1>/, '')
		return title, content_minus_title
	end

	def slugify(title)
		title.downcase.gsub(/[^a-z0-9 -]/, '').gsub(/ /, '-')
	end

	def toc(content)
		toc = content.scan(/<h2>([^<]+)<\/h2>/m).to_a.map { |m| m.first }
		content_with_anchors = content.gsub(/(<h2>[^<]+<\/h2>)/m) do |m|
			"<a name=\"#{slugify(m.gsub(/<[^>]+>/, ''))}\"></a>#{m}"
		end
		return toc, content_with_anchors
	end

	def sections
		[
			[ 'quickstart', 'Quickstart' ],
			[ 'heroku-command', 'Heroku command-line tool' ],
			[ 'git', 'Using Git' ],
			[ 'sharing', 'Sharing' ],
			[ 'console-rake', 'Console and rake' ],
			[ 'rack', 'Deploying Rack-based apps' ],
			[ 'logs-exceptions', 'Logs and exceptions' ],
			[ 'errors', 'Errors' ],
			[ 'addons', 'Add-ons' ],
			[ 'custom-domains', 'Custom domain names' ],
			[ 'gems', 'Installing gems' ],
			[ 'taps', 'Database import/export' ],
			[ 'renaming-apps', 'Renaming apps' ],
			[ 'cron', 'Cron jobs' ],
			[ 'background-jobs', 'Background jobs' ],
			[ 'config-vars', 'Config vars' ],
			[ 'http-caching', 'HTTP caching' ],
			[ 'full-text-indexing', 'Full text indexing' ],
			[ 'constraints', 'Constraints' ],
			[ 'technologies', 'Technologies' ],
		]
	end

	def next_section(current_slug)
		return sections.first if current_slug.nil?

		sections.each_with_index do |(slug, title), i|
			if current_slug == slug and i < sections.length-1
				return sections[i+1]
			end
		end
		nil
	end

	alias_method :h, :escape_html
end
