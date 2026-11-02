function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

// Runs a query or mutation against /graphql. Throws on transport or GraphQL errors.
export async function gql(query, variables = {}) {
  const response = await fetch("/graphql", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": csrfToken() },
    credentials: "same-origin",
    body: JSON.stringify({ query, variables }),
  })
  if (!response.ok) throw new Error(`Server error (${response.status})`)

  const body = await response.json()
  if (body.errors?.length) throw new Error(body.errors.map((e) => e.message).join(", "))
  return body.data
}

// Runs a mutation whose payload has an `errors` list of user-facing messages.
export async function mutate(query, variables, key) {
  const data = await gql(query, variables)
  const payload = data[key]
  if (payload.errors?.length) throw new Error(payload.errors.join(", "))
  return payload
}
