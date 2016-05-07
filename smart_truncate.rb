#    smart_truncate: A HTML-aware word-truncating filter for Jekyll/Liquid
#    Copyright © 2016  RunasSudo (Yingtong Li)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Code style: Smells like Python

require 'nokogiri'

module Jekyll
	module SmartTruncate
		def smart_truncate(input, num_words=100, after='...')
			doc = Nokogiri::HTML(input)
			smart_truncate_doc(doc, num_words)
			
			body = doc.root.children.first
			
			if body.children.last.name == 'p' || body.children.last.name == 'div' || body.children.last.name == 'span'
				body.children.last.inner_html += after
			else
				body << after
			end
			
			return body.inner_html
		end
		
		def smart_truncate_doc(doc, num_words)
			if doc.is_a?(Nokogiri::XML::Text)
				if num_words > 0
					if doc.content.split().length <= num_words # Enough words
						return doc.content.split().length
					else # Must break here
						new_content = doc.content.split()[0 .. num_words - 1].join(' ')
						
						if doc.content.start_with?(' ')
							doc.content = ' ' + new_content # Preserve leading space
							# If we're breaking, then trailing spaces don't matter
						else
							doc.content = new_content
						end
						
						return num_words
					end
				else
					doc.remove()
					return 0
				end
			elsif doc.name == 'table'
				return smart_truncate_table(doc, num_words)
			else
				count = 0
				doc.children.each do |child|
					count += smart_truncate_doc(child, num_words - count)
				end
				
				if doc.children.length == 0
					doc.remove()
				end
				
				return count
			end
		end
		
		def smart_truncate_table(doc, num_words)
			if doc.is_a?(Nokogiri::XML::Text)
				return doc.content.split().length
			elsif doc.name == 'tr'
				if num_words <= 0 # Cut off at the row level
					doc.remove()
					return 0
				else
					count = 0
					doc.children.each do |child|
						count += smart_truncate_table(child, num_words - count)
					end
					return count
				end
			else
				count = 0
				doc.children.each do |child|
					count += smart_truncate_table(child, num_words - count)
				end
				
				if doc.children.length == 0
					doc.remove()
				end
				
				return count
			end
		end
	end
end

Liquid::Template.register_filter(Jekyll::SmartTruncate)
