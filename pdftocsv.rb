#!/usr/bin/env ruby
require 'date'
require 'pdf-reader'

def barclays_parse(lines)
	Enumerator.new do |enum|
		for line in lines
			case line
			when :new_file
				go = false
				data = {}
			when ""
				# puts  # XXX DEBUG
			when /^Date  *Description/
				go = true
				# puts line  # XXX DEBUG
			when /^(\d\d? [A-Z][a-z]{2})?  *(\S.*?)     *([0-9,]+\.\d\d)(     *[0-9,]+\.\d\d)?/
				enum.yield data unless data.empty?
				# XXX: Fix dates, they currently default to THIS year
				data[:date] = $1 ? Date.parse($1) : nil
				data[:description], data[:ref] = $2, nil
				data[:transaction], data[:balance] = [ $3, $4 ].map{ |e| e.gsub(",", "").to_f if e }
				if data[:description] =~ /^((Start|End) balance|Balance)$/
					go = $2 == "Start"
					# Blank sheets have only "Balance", and will result in 2 :ends in a row
					data[:description] = go ? :start : :end
					data[:balance] = data[:transaction]
					data[:transaction] = nil
				end
				enum.yield data unless go
				# puts "\e[33m#{line}\e[m"  # XXX DEBUG
			when /( * Ref: )(.*?)(      .*|$)/
				data[3] = $2
				# puts "#{$1}\e[32m#{$2}\e[m#{$3}"  # XXX DEBUG
				# END of page
			when / {20} *Continued/
				go = false
				enum.yield data
				# puts line  # XXX DEBUG
				# DESCRIPTION  # XXX Exclude lines indented by >20 spaces?
			when /(^ {0,40})(\S.*?)( {7}|$)/
				if go
					data[:description] << " " + $2
					# puts "#{$1}\e[32m#{$2}\e[m"  # XXX DEBUG
				else
					# puts "#{$1}#{$2}"  # XXX DEBUG
				end
			else
				# puts "\e[1;31m#{line}\e[m"  # XXX DEBUG
			end
		end
	end
end

def readlines(files)
	Enumerator.new do |enum|
		files.each do |file|
			# puts "\e[1m##### #{file} #####\e[m"  # XXX DEBUG
			File.open(file, "rb") do |io|
				begin
					reader = PDF::Reader.new(io)
				rescue PDF::Reader::MalformedPDFError
					next
				end
				enum.yield :new_file
				reader.pages[0..-2].map{ |page| page.text.split("\n") }.flatten.each do |line|
					enum.yield line
				end
			end
		end
	end
end

barclays_parse(readlines(ARGV)).each do |i|
	date = i[:date] ||= " " * 10
	transaction = i[:transaction] ? "% 10.2f" % i[:transaction] : " " * 10
	balance = i[:balance] ? "% 10.2f" % i[:balance] : " " * 10
	puts "\e[33m%s\t%s\t%s\t%s\t%s\e[m" % [ date, transaction, balance, i[:ref], i[:description] ]
end

# 	transactions = amounts.select.each_with_index{ |a, i| i.odd? }
# 	balances = amounts.select.each_with_index{ |a, i| i.even? }

# 	calculated_transactions = balances.each_cons(2).map do |p, n|
# 		n - p
# 	end

# 	begin
# 		# Verify final balance:
# 		raise "Couldn't verify final balance." unless transactions.last == balances.last

# 		# Verify that transactions and balances match:
# 		calculated_transactions.each_with_index do |t, i|
# 			unless t.abs == transactions[i].abs
# 				raise "Transaction #{i} does not balance."
# 			end
# 		end

# 	rescue RuntimeError
# 		puts "From sheet:"
# 		amounts.each_with_index do |a, i|
# 			type = i.even? ? "balance" : "transaction"
# 			puts "\t#{a} (#{type})"
# 		end
# 		puts "Calculated transactions:"
# 		puts calculated_transactions.map{ |t| "\t" + t.to_s }
# 		raise
# 	end

# 	calculated_transactions.unshift(nil)
# 	info.map!.each_with_index do |t, i|
# 		[ t[0], calculated_transactions[i], t[1..-1].join("").gsub("\n", " ") ]
# 	end

# 	# Output:
# 	info.each do |i|
# 		if i[1]
# 			puts "%s   % 10.2f   %s" % [ i[0], i[1], i[2] ]
# 		else
# 			puts "%s                %s" % [ i[0], i[2] ]
# 		end
# 		# puts i
# 		# puts "----"
# 	end

# end
