require 'spec_helper'
require 'flapjack/gateways/jsonapi'

describe 'Flapjack::Gateways::JSONAPI::Methods::Checks', :sinatra => true, :logger => true, :pact_fixture => true do

  include_context "jsonapi"

  let(:check) { double(Flapjack::Data::Check, :id => check_data[:id]) }
  let(:tag)   { double(Flapjack::Data::Tag, :id => tag_data[:id]) }

  let(:check_presenter) { double(Flapjack::Gateways::JSONAPI::Helpers::CheckPresenter) }

  it "creates a check" do
    expect(Flapjack::Data::Check).to receive(:lock).with(Flapjack::Data::Tag).and_yield
    empty_ids = double('empty_ids')
    expect(empty_ids).to receive(:ids).and_return([])
    expect(Flapjack::Data::Check).to receive(:intersect).
      with(:id => [check_data[:id]]).and_return(empty_ids)

    expect(check).to receive(:invalid?).and_return(false)
    expect(check).to receive(:save).and_return(true)
    expect(Flapjack::Data::Check).to receive(:new).with(check_data).
      and_return(check)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id],
           :unwrap => true).and_return(check_data)

    post "/checks", Flapjack.dump_json(:checks => check_data), jsonapi_post_env
    expect(last_response.status).to eq(201)
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => check_data))
  end

  it "creates a check with a linked tag" do
    check_with_tag_data = check_data.merge(:links => {:tags => [tag_data[:id]]})

    expect(Flapjack::Data::Check).to receive(:lock).with(Flapjack::Data::Tag).and_yield
    empty_ids = double('empty_ids')
    expect(empty_ids).to receive(:ids).and_return([])
    expect(Flapjack::Data::Check).to receive(:intersect).
      with(:id => [check_with_tag_data[:id]]).and_return(empty_ids)

    expect(check).to receive(:invalid?).and_return(false)
    expect(check).to receive(:save).and_return(true)
    expect(Flapjack::Data::Check).to receive(:new).with(check_data).
      and_return(check)

    expect(Flapjack::Data::Tag).to receive(:find_by_ids!).with(tag_data[:id]).
      and_return([tag])
    check_tags = double('check_tags')
    expect(check_tags).to receive(:add).with(tag)
    expect(check).to receive(:tags).and_return(check_tags)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id],
           :unwrap => true).and_return(check_with_tag_data)

    post "/checks", Flapjack.dump_json(:checks => check_with_tag_data), jsonapi_post_env
    expect(last_response.status).to eq(201)
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => check_with_tag_data))
  end

  it "retrieves paginated checks" do
    meta = {
      :pagination => {
        :page        => 1,
        :per_page    => 20,
        :total_pages => 1,
        :total_count => 1
      }
    }

    expect(Flapjack::Data::Check).to receive(:count).and_return(1)

    sorted = double('sorted')
    expect(sorted).to receive(:page).with(1, :per_page => 20).
      and_return([check])
    expect(Flapjack::Data::Check).to receive(:sort).
      with(:name).and_return(sorted)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id], :unwrap => false,
           :fields => an_instance_of(Array)).
      and_return([check_data])

    get '/checks'
    expect(last_response).to be_ok
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => [check_data], :meta => meta))
  end

  it "retrieves one check" do
    expect(Flapjack::Data::Check).to receive(:find_by_id!).
      with(check.id).and_return(check)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id], :unwrap => true,
           :fields => an_instance_of(Array)).
      and_return(check_data)

    get "/checks/#{check.id}"
    expect(last_response).to be_ok
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => check_data))
  end

  it "retrieves one check with a subset of fields" do
    expect(Flapjack::Data::Check).to receive(:find_by_id!).
      with(check.id).and_return(check)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id], :unwrap => true,
           :fields => [:name, :enabled, :id]).
      and_return(check_data)

    get "/checks/#{check.id}?fields=name,enabled"
    expect(last_response).to be_ok
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => check_data))
  end

  it "retrieves one check and all its linked tag records" do
    expect(Flapjack::Data::Check).to receive(:find_by_id!).
      with(check.id).and_return(check)

    check_with_tag_data = check_data.merge(:links => {:tags => [tag.id]})

    checks = double('checks')
    expect(checks).to receive(:associated_ids_for).with(:tags).
      and_return(check.id => [tag.id])
    expect(Flapjack::Data::Check).to receive(:intersect).
      with(:id => [check.id]).and_return(checks)

    expect(Flapjack::Data::Tag).to receive(:find_by_ids!).
      with(tag.id).and_return([tag])

    expect(Flapjack::Data::Tag).to receive(:as_jsonapi).
      with(:resources => [tag], :ids => [tag.id], :unwrap => false).
      and_return(tag_data)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check], :ids => [check.id], :unwrap => true,
           :fields => an_instance_of(Array)).
      and_return(check_with_tag_data)

    get "/checks/#{check.id}?include=tags"
    expect(last_response).to be_ok
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => check_with_tag_data,
      :linked => {:tags => tag_data}))
  end

  it "retrieves several checks" do
    check_2 = double(Flapjack::Data::Check, :id => check_2_data[:id])

    sorted = double('sorted')
    expect(sorted).to receive(:find_by_ids!).
      with(check.id, check_2.id).and_return([check, check_2])
    expect(Flapjack::Data::Check).to receive(:sort).with(:name).and_return(sorted)

    expect(Flapjack::Data::Check).to receive(:as_jsonapi).
      with(:resources => [check, check_2], :ids => [check.id, check_2.id],
           :unwrap => false, :fields => an_instance_of(Array)).
      and_return([check_data, check_2_data])

    get "/checks/#{check.id},#{check_2.id}"
    expect(last_response).to be_ok
    expect(last_response.body).to eq(Flapjack.dump_json(:checks => [check_data, check_2_data]))
  end

  it 'disables a check' do
    expect(Flapjack::Data::Check).to receive(:find_by_ids!).
      with(check.id).and_return([check])

    expect(check).to receive(:enabled=).with(false)
    expect(check).to receive(:invalid?).and_return(false)
    expect(check).to receive(:save).and_return(true)

    put "/checks/#{check.id}",
      Flapjack.dump_json(:checks => {:id => check.id, :enabled => false}),
      jsonapi_put_env
    expect(last_response.status).to eq(204)
  end

end
