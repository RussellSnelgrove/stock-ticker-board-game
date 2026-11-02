import { createConsumer } from "@rails/actioncable"

let consumer

// Subscribes to a GraphQL subscription over GraphqlChannel (graphql-ruby ActionCableSubscriptions).
// Returns a function that unsubscribes.
export function subscribe(query, variables, onData) {
  consumer ||= createConsumer()
  const channelId = Math.random().toString(36).slice(2)

  const channel = consumer.subscriptions.create(
    { channel: "GraphqlChannel", channelId },
    {
      connected() {
        this.perform("execute", { query, variables })
      },
      received(payload) {
        const result = payload.result
        if (result?.errors?.length) console.warn("Subscription error", result.errors)
        if (result?.data) onData(result.data)
      },
    },
  )

  return () => channel.unsubscribe()
}
