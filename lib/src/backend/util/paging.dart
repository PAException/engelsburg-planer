/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

/// Util class to handle general paging
class Paging {
  //Start -> 0 (First page)
  final int page;

  //Start -> 1
  final int size;

  const Paging(this.page, this.size);
}
