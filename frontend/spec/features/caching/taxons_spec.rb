require 'spec_helper'

describe 'taxons', :caching => true do
  let!(:taxonomy) { create(:taxonomy) }
  let!(:taxon) { create(:taxon, :taxonomy => taxonomy) }
  let!(:taxon2) { create(:taxon, :taxonomy => taxonomy) }

  before do
    taxon2.update_column(:updated_at, 1.day.ago)
    # warm up the cache
    visit spree.root_path
    assert_written_to_cache("views/spree/taxonomies/#{taxonomy.id}")
    assert_written_to_cache("views/taxons/#{taxon.updated_at.utc.to_i}")

    clear_cache_events
  end

  it "reads from cache upon a second viewing" do
    visit spree.root_path
    expect(cache_writes.count).to eq(0)
  end

  it "busts the cache when a taxon is updated" do
    taxon.update_column(:updated_at, 1.day.from_now)
    visit spree.root_path
    assert_written_to_cache("views/taxons/#{taxon.updated_at.utc.to_i}")
    expect(cache_writes.count).to eq(1)
  end

  it "busts the cache when a taxonomy is updated" do
    taxonomy.update_column(:updated_at, 1.day.from_now)
    visit spree.root_path
    assert_written_to_cache("views/spree/taxonomies/#{taxonomy.id}")
    expect(cache_writes.count).to eq(1)
  end

  it "busts the cache when all taxons are deleted" do
    taxon.destroy
    taxon2.destroy
    visit spree.root_path
    assert_written_to_cache("views/spree/taxonomies/#{taxonomy.id}")
    expect(cache_writes.count).to eq(1)
  end

  it "busts the cache when the newest taxon is deleted" do
    taxon.destroy
    visit spree.root_path
    assert_written_to_cache("views/spree/taxonomies/#{taxonomy.id}")
    expect(cache_writes.count).to eq(1)
  end

  # it "busts the cache when an older taxon is deleted" do
  #   taxon2.destroy
  #   visit spree.root_path
  #   assert_written_to_cache("views/taxons/#{taxon.updated_at.utc.to_i}")
  #   expect(cache_writes.count).to eq(1)
  # end

  it "busts the cache when max_level_in_taxons_menu conf changes" do
    Spree::Config[:max_level_in_taxons_menu] = 5
    visit spree.root_path
    assert_written_to_cache("views/spree/taxonomies/#{taxonomy.id}")
    expect(cache_writes.count).to eq(1)
  end
end
