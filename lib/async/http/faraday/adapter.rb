# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'faraday'
require 'faraday/adapter'
require 'async/http/internet'

module Async
	module HTTP
		module Faraday
			# Detect whether we can use persistent connections:
			PERSISTENT = ::Faraday::Connection.instance_methods.include?(:close)
			
			class Adapter < ::Faraday::Adapter
				def initialize(*arguments, **options, &block)
					super
					
					@internet = Async::HTTP::Internet.new
				end
				
				def close
					@internet.close
				end
				
				def call(env)
					super
					
					response = @internet.call(env[:method], env[:url].to_s, env[:request_headers], env[:body])
					
					save_response(env, response.status, response.read, response.headers)
					
					return @app.call(env)
				ensure
					# Don't retain persistent connections unless they will eventually be closed:
					@internet.close unless PERSISTENT
				end
			end
		end
	end
end
