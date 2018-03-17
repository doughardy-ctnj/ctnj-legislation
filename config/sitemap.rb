# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://bills.ctnewsjunkie.com"

SitemapGenerator::Sitemap.create do
  Bill.find_each do |bill|
    add bill_path(bill), lastmod: bill.updated_at
  end
end
