class Triage < Schematist::Schema
  string :intent, enum: %w[order_status refund complaint other]
  string :summary
end
