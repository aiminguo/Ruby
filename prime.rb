class CachedPrime
	private
	def is_prime?(num)
		square_root = Math.sqrt(num).ceil
		 
		@primes.each do |prime|
			return false if num % prime == 0 # The number is not prime		 
			# Reached the upper bound of possible factors
			break if prime > square_root
		end
		true
	end
 
	# Public: Initializes the list of primes
	public
	def initialize
		# Known: 2 is the first and only even prime
		@primes = [2, 3]
	end
 
	# Public: Finds the nth prime number
	def get_nth_prime(n)
		unless n > 0 
			raise  'Expected a positive integer'
		end

		return @primes[n - 1] if @primes[n - 1]
		 
		# Only check the odd numbers
		temp = @primes.last + 2
		 
		while @primes.size < n
			@primes.push temp if is_prime?(temp)
			temp += 2
		 end
		
		return @primes.last
	end
end
