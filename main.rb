#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'

def api(token, url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Accept'] = 'application/vnd.github.v3+json'
  request['Authorization'] = "token #{token.strip}"
  response = http.request(request)
  response.code == '302' ? api(token, response.header['location']) : response.body
end

repo = ENV['GITHUB_REPOSITORY']
token = ENV['INPUT_GITHUB_TOKEN']
workflow = ENV['INPUT_WORKFLOW']
commit = ENV['INPUT_COMMIT']
name = ENV['INPUT_NAME']
path = ENV['INPUT_PATH'] || './'

api = 'https://api.github.com'

runs = api(token, "#{api}/repos/#{repo}/actions/workflows/#{workflow}/runs")
runs = JSON.parse(runs)

run = runs['workflow_runs'].find do |r|
  r['head_sha'] == commit
end

puts "==> Run: #{run}"

artifacts = api(token, run['artifacts_url'])
artifacts = JSON.parse(artifacts)
artifact = artifacts['artifacts'].find do |a|
  a['name'] == name
end

puts "==> Artifacts: #{artifacts['total_count']}"

archive = api(token, artifact['archive_download_url'])
filename = "#{name}.zip"
File.write(filename, archive)
exit 1 unless system('unzip', '-o', '-d', path, filename)
