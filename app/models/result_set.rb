require 'digest/md5'

class ResultSet < ActiveRecord::Base
  serialize :domains, Array
  serialize :data, Array

  validates :email, uniqueness: {scope: [:first_name, :last_name, :domain_hash]}

  def domains=(v)
    domains = v | default_domains
    self[:domains] = domains
    self[:domain_hash] = Digest::MD5.hexdigest(domains.sort.join(','))
  end

  def first_name=(v)
    self[:first_name] = v.to_s.titleize
  end

  def last_name=(v)
    self[:last_name] = v.to_s.titleize
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def get_results
    if data.present? && updated_at > 24.hours.ago
      return data
    end
    if email
      self.data = get_results_from_email
    else
      self.data = get_results_from_name
    end
    save
    data.sort_by { |x| x.first }
  end

  private

  def default_domains
    ['gmail.com', 'live.com', 'hotmail.com', 'yahoo.com']
  end

  def get_results_from_email
    results = PossibleEmail.find_profile(email)
    format_results results
  end

  def get_results_from_name
    results = PossibleEmail.search(first_name, last_name, domains)
    format_results results
  end

  def format_results(results)
    if results.respond_to? :each
      results.map! do |result|
        if result.name == full_name
          [2, result]
        elsif result.first_name == first_name || result.last_name == last_name
          [1, result]
        else
          [0, result]
        end
      end
    else
      results = [[0, results]]
    end
  end


end
