# typed: false
# frozen_string_literal: true

module Compare
  def levenshtein_distance(s1, s2)
    m = s1.length
    n = s2.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..n).each do |j|
      (1..m).each do |i|
        match = (s1[i - 1] == s2[j - 1]) ? 0 : 1
        d[i][j] =
          [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + match].min
      end
    end

    d[m][n]
  end

  def sorensen_dice_coefficient(s1, s2)
    bigram1 = s1.each_char.each_cons(2).to_a
    bigram2 = s2.each_char.each_cons(2).to_a

    intersection = (bigram1 & bigram2).size
    total = bigram1.size + bigram2.size

    2.0 * intersection / total
  end

  def jaro_distance(s1, s2)
    return 1.0 if s1 == s2

    len1 = s1.length
    len2 = s2.length
    max_dist = [(len1 / 2) - 1, 0].max
    match = 0

    hash_s1 = s1.chars.map { false }
    hash_s2 = s2.chars.map { false }

    s1.chars.each_with_index do |ch1, i|
      (([i - max_dist, 0].max)..([i + max_dist, len2 - 1].min)).each do |j|
        next unless ch1 == s2[j] && !hash_s2[j]
        hash_s1[i] = true
        hash_s2[j] = true
        match += 1
        break
      end
    end

    return 0.0 if match.zero?

    k = transposition_count = 0
    s1.chars.each_with_index do |ch1, i|
      next unless hash_s1[i]
      k += 1 until hash_s2[k]
      transposition_count += 1 if ch1 != s2[k]
      k += 1
    end

    transpositions = transposition_count / 2.0

    ((match / len1.to_f) + (match / len2.to_f) + ((match - transpositions) / match.to_f)) / 3.0
  end

  def jaro_winkler_distance(s1, s2, scaling_factor: 0.1)
    jaro_dist = jaro_distance(s1, s2)

    prefix = 0
    prefix_limit = [s1.length, s2.length, 4].min
    prefix_limit.times do |i|
      break if s1[i] != s2[i]
      prefix += 1
    end

    jaro_dist + ((prefix * scaling_factor) * (1 - jaro_dist))
  end

  def generate_trigrams(s)
    s = "  #{s}  "
    trigrams = []
    (0..s.length - 3).each do |i|
      trigrams << s[i, 3]
    end
    trigrams
  end

  def trigram_similarity(s1, s2)
    trigrams1 = generate_trigrams(s1)
    trigrams2 = generate_trigrams(s2)

    intersection = (trigrams1 & trigrams2).size

    union = trigrams1.size + trigrams2.size - intersection

    intersection.to_f / union
  end

  def composite_similarity(s1, s2)
    levenshtein = 1 - (levenshtein_distance(
      s1,
      s2
    ).to_f / [s1.size, s2.size].max)
    dice = sorensen_dice_coefficient(s1, s2)
    jaro_winkler = jaro_winkler_distance(s1, s2)
    trigram = trigram_similarity(s1, s2)
    (levenshtein + dice + jaro_winkler + trigram) / 4.0
  end
end

