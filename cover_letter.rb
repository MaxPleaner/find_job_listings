module CoverLetter
	def self.default
		puts File.read('CoverLetter.txt')
	end
end

if __FILE__ == $0
	CoverLetter.default
end