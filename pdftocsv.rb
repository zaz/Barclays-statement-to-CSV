#!/usr/bin/env ruby
require 'date'
require 'pdf-reader'

# XXX Look into using a Fibre instead of a class
class BarclaysParser
	include Enumerable

	def initialize(lines, expected_start_date=nil, expected_start_balance=nil)
		@lines = lines
		@go = false
		@data = nil
	end

	def <<(val)
		@lines << val
	end

	def each(&lines)
		@lines.each do |line|
			case line
			when ""
				# puts  # XXX DEBUG
			when /^Date  *Description/
				@go = true
				# puts line  # XXX DEBUG
			when /^(\d\d? [A-Z][a-z]{2})?  *(\S.*?)     *([0-9,]+\.\d\d)(     *[0-9,]+\.\d\d)?/
				# XXX: Fix dates, they currently default to THIS year
				date = $1 ? Date.parse($1) : nil
				description, ref = $2, nil
				transaction, balance = [ $3, $4 ].map{ |e| e.gsub(",", "").to_f if e }
				if description =~ /^((Start|End) balance|Balance)$/
					@go = $2 == "Start"
					# Blank sheets have only "Balance", and will result in 2 :ends in a row
					description = @go ? :start : :end
					balance = transaction
					transaction = nil
				end
				# TODO: Use a hash instead
				yield @data if @data
				@data = [ date, transaction, balance, ref, description ]
				yield @data unless @go
				# puts "\e[33m#{line}\e[m"  # XXX DEBUG
			when /( * Ref: )(.*?)(      .*|$)/
				@data[3] = $2
				# puts "#{$1}\e[32m#{$2}\e[m#{$3}"  # XXX DEBUG
			# END of page
			when / {20} *Continued/
				@go = false
				yield @data
				# puts line  # XXX DEBUG
			# DESCRIPTION  # XXX Exclude lines indented by >20 spaces?
			when /(^ {0,40})(\S.*?)( {7}|$)/
				if @go
					@data[-1][-1] << " " + $2
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

parser = nil
ARGV.each do |file|
	# XXX: Catch PDF::Reader::MalformedPDFError instead
	next unless file =~ /\.pdf$/
	# puts "\e[1m##### #{file} #####\e[m"  # XXX DEBUG

	File.open(file, "rb") do |io|
		reader = PDF::Reader.new(io)
		lines = reader.pages[0..-2].map{ |page| page.text.split("\n") }.flatten
		parser = BarclaysParser.new(lines)

		# data << parser.parse(lines)
		# lines_enumerator = lines.each
		# data << parser.parse(lines_enumerator).each

		parser.each do |i|
			date = i[0] ||= " " * 10
			transaction = i[1] ? "% 10.2f" % i[1] : " " * 10
			balance = i[2] ? "% 10.2f" % i[2] : " " * 10
			puts "\e[33m%s\t%s\t%s\t%s\t%s\e[m" % [ date, transaction, balance, i[3], i[4] ]
		end

	end

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
