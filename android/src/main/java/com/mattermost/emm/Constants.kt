package com.mattermost.emm

const val E_ACTIVITY_DOES_NOT_EXIST: String = "E_ACTIVITY_DOES_NOT_EXIST"
const val E_ONE_REQ_AT_A_TIME: String = "E_ONE_REQ_AT_A_TIME"

// Shared with iOS. Only FAILED means a credential was offered and rejected; the other
// two must never lead to a destructive action such as logging the user out.
const val FAILED: String = "E_AUTH_FAILED"
const val REQUEST: Int = 18864
const val CANCELLED: String = "E_CANCELLED"
const val ERROR: String = "E_INDETERMINATE"
