#!/usr/bin/env ruby
require 'date'

info = []
amounts = []

op = :preface

ARGV.each do |file|
	next unless file =~ /\.pdf$/
	puts "##### #{file} #####"

	IO.popen("pdftotext #{file} - 2>/dev/null").each do |line|
		case line
		when "\n"
		when "Balance\n"
			op = :transactions
		when /^\d\d? [A-Z][a-z]{2}$/
			info << [ Date.parse( line ) ]
		when /^(\d\d? [A-Z][a-z]{2}) (.*)$/
			next if line =~ /^(\d\d [A-Z][a-z]{2}) \d{4} /
			match = /^(\d\d [A-Z][a-z]{2}) (.*)$/.match(line)
			info << [ Date.parse( match[1] ), match[2] ]
		when /^\d+.\d\d$/
			amounts << line.to_f
		else
			info.last << line if op == :transactions
			op = :end if line == "End balance\n"
		end
	end

	transactions = amounts.select.each_with_index{ |a, i| i.odd? }
	balances = amounts.select.each_with_index{ |a, i| i.even? }

	calculated_transactions = balances.each_cons(2).map do |p, n|
		n - p
	end

	# Verify final balance:
	raise "Couldn't verify final balance." unless transactions.last == balances.last

	# Verify that transactions and balances match:
	calculated_transactions.each_with_index do |t, i|
		raise "Transaction #{i} does not balance." unless t.abs == transactions[i]
	end

	calculated_transactions.unshift(nil)
	info.map!.each_with_index do |t, i|
		[ t[0], calculated_transactions[i], t[1..-1].join("").gsub("\n", " ") ]
	end

	# Output:
	info.each do |i|
		puts i
		puts "----"
	end

end
