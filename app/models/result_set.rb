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

  def initials
    "?" unless full_name.strip.present?
    "#{first_name[0]}" "#{last_name[0]}"
  end

  def get_results
    if data.present? && updated_at > 24.hours.ago
      return data
    end
    if email.present?
      self.data = get_results_from_email
    else
      self.data = get_results_from_name
    end
    save
    data
  end

  def self.find_or_create(params)
    begin
      result_set = ResultSet.new params
      result_set.save!
    rescue ActiveRecord::RecordInvalid
      result_set = ResultSet.first_or_create params
    end
    result_set
  end

  private

  def get_image(data)
    data['images'].each do |image|
      begin
        RestClient.get image['url']
      rescue
      else
        return image['url'].include?('gravatar') ? "#{image['url']}&s=200" : image['url']
      end
    end
    "http://placehold.it/200&text=#{initials}"
  end

  def self.result_to_h(result)
    JSON.parse(result.to_json)
  end

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
      results.to_a.map! do |result|
        result = ResultSet.result_to_h(result)
        result['image'] = get_image(result)
        if result['name'] == full_name
          [2, result]
        elsif result['first_name'] == first_name || result['last_name'] == last_name
          [1, result]
        else
          [0, result]
        end
      end
    else
      result = ResultSet.result_to_h(results)
      result['image'] = get_image(result)
      [[2, result]]
    end
  end


end
