#!/usr/bin/ruby -w
# Frozen_String_Literal: true
# https://en.wikipedia.org/wiki/VCard

Hash.define_method(:fetch_r) { |reg| keys.select { |x| x[reg] }.map! { |x| self[x] } }
PATH = File.dirname($0)

VCF = Class.new do
	# Append data to a vcf file / create a new vcf file
	define_singleton_method(:create) do |name, n:, fn:, telcell: nil, telwork: nil, telhome: nil, telhomefax: nil|
		telcell = telcell ? "\r\nTEL;CELL:#{telcell.to_i}" : ''
		telwork = telwork ? "\r\nTEL;WORK:#{telwork.to_i}" : ''
		telhome = telhome ? "\r\nTEL;HOME:#{telhome.to_i}" : ''
		telhomefax = telhomefax ? "\r\nTEL;HOME;FAX:#{telhomefax.to_i}" : ''

		data = <<~EOF.tap { |x|  }
			BEGIN:VCARD\r
			VERSION:2.1\r
			N:;#{n};;;\r
			FN:#{fn}#{telcell}#{telwork}#{telhome}#{telhomefax}\r
			END:VCARD\r
		EOF

		begin
			n = name.end_with?('vcf') ? name : "#{name}.vcf"
			if IO.read(n).include?(data)
				warn("#{n} already contains the data:\n#{data.lines.map { |x| "\t#{x}" }.join}The file #{File.basename(n)} is not written...")
			else
				File.open(n, ?a) { |x| x.puts(data) }
			end
		rescue Errno::EACCES
			STDERR.puts "Permission denied while attempted to write to #{n}"
		rescue Exception
			STDERR.puts $!
			STDERR.puts "Uh oh! An Error Just Occurred!", $!.backtrace.map! { |x| "\t#{x}" }
		end

		data
	end

	def initialize(data)
		@data = data.split('END:VCARD').map! { |x| x.tap(&:strip!).split(/\r\n/) }.reject!(&:empty?).map!(&:freeze).freeze
		@arr = @data.map { |x| x.drop(2).reduce({}) { |z, y| z.merge!(y.split(?:).then { |z| {z[0].to_s.gsub(?;, ?-) => z[1].to_s.gsub(?;, ?\s).tap(&:strip!) } }) } }.freeze
	end

	def search(field)
		f = field.downcase
		@arr.select { |x| x.values.any? { |y| y.downcase.then { |z| z.include?(f) || z.delete(?\s).include?(f) } } }
	end

	define_method(:keys) { @arr.map(&:keys) }
	define_method(:values) { @arr.map(&:values) }
	define_method(:to_s) { "<<Class: #{send(:class)}> <Variables: #{instance_variables.join(', ')}> <Methods: #{public_methods.reverse.drop(56).join(', ')}>>" }
	def [](arg) @arr.map { |x| x.fetch_r(arg)[0] }.tap(&:compact!) end

	define_method(:fetch) { |key1, key2| @arr.map { |x| {key1 => x.fetch_r(key2)} if x.values.any? { |y| y[key1] || y[key2] } }.tap(&:compact!) }
	define_method(:to_h) { @arr }

	alias :inspect :to_s
	alias :to_hash :to_h
end

contacts = VCF.new(File.read(File.join(PATH, '00001.vcf')))
# p contacts.search('sik')
# p contacts[/^TEL.+$/]
# p contacts.to_h
p VCF.create(File.join(PATH, 'hello'), n: :Sourav, fn: 'Sourav Goswami', telcell: 9840222222)
p contacts.to_h

# p contacts[/^TEL.+$/]
# p contacts.search '96740'
# p contacts.search('kausik')
# p contacts.fetch('Kausik', /TEL.*/)
# p
