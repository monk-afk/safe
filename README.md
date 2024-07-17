# Locked Safe

A Passcode Protected Inventory Node. Secured with Pure-Lua SHA3 Encryption.

___

## WARNING!

# BIG WARNING READ VERY CAREFULLY

> [!WARNING]
> DO NOT REUSE PASSWORD OR PIN WITH THIS MOD! Create a new-to-you passcode.

Minetest does not encrypt network traffic between a server and it's clients.

This means, once connected to a server all data you send to and receive from the server is vulnerable to eavesdropping.

Vicariously, that makes this mod also vulnerable regardless of any encryption method.

This will eventually be addressed in future updates to Minetest. Until then, this warning must stay posted.

___

## Overview

- Features
  - Records Access and Activity Logs
  - Authentication data is encrypted with SHA3-224

- Configuration
  - Safe-Admin sets Initial Ownership, there's no craft recipe
  - The Safe's Owner sets the initial PIN

- Access Logs
  - Records the following events:
  - `Authenticated`: Access with Correct PIN
  - `New PIN Set`: PIN changed
  - `Generate Keys`: Generated new set of Recovery Keys
  - `Used Recovery Key`: A Recovery Key was used
  - `Bad Recovery Key`: Incorrect Recovery Key used
  - `Bypass Attempt`: Attempt to access node data
  - `Incorrect PIN`: Incorrect PIN entry

- Recovery Keys
  - Generates six single-use Recovery Keys to reset forgotten PIN
  - A Safe without a PIN is still secured from unauthorized access
  - Forces regenerating new Keys if there are only two Keys remaining
  - After using a Recovery Key, new Keys may not be generated for 72 hours


## Changelog

0.0.1
  - Initial Release

## Attributions

- Safe, Copyright (c) 2024 monk <monk.squareone@gmail.com>
  - MIT License, Source: https://github.com/monk-afk/safe

- pure_lua_SHA, Copyright (c) 2018-2022  Egor Skriptunoff
  - MIT License, Source: https://github.com/Egor-Skriptunoff/pure_lua_SHA

- sfinv, Copyright (C) 2016-2018 rubenwardy <rubenwardy@gmail.com>
  - MIT License, Source: https://github.com/rubenwardy/sfinv

- Safe Textures, Copyright (c) 2014 Vanessa Ezekowitz
 - CC-by-SA 4.0 License, Source: https://github.com/mt-mods/currency