for _, rowII in dfII_sel.reset_index(drop=True).iterrows():
    # ==== REGLA FORZADA: mapear ISINs específicos a clases SAM concretas ====
    _force_spb_isins = {"ES0112793031", "ES0112793007"}
    _force_rf_ahorro_isins = {"ES0112793049", "ES0112793023"}

    picked = None
    isin_ii = str(rowII.get("ISIN", "")).strip().upper()

    if isin_ii in _force_spb_isins:
        target_isin = "ES0174735037"
        sam_rec = next((r for r in SAM_CLEAN_MAP if str(r.get("ISIN", "")).strip().upper() == target_isin), None)
        if sam_rec is not None:
            picked = pd.Series({c: sam_rec.get(c, "") for c in cols_I}, index=cols_I)
            rows_I.append(picked.reindex(cols_I) if picked is not None else pd.Series(index=cols_I, dtype="object"))
            continue

    if isin_ii in _force_rf_ahorro_isins:
        target_isin = "ES0112793015"
        sam_rec = next((r for r in SAM_CLEAN_MAP if str(r.get("ISIN", "")).strip().upper() == target_isin), None)
        if sam_rec is not None:
            picked = pd.Series({c: sam_rec.get(c, "") for c in cols_I}, index=cols_I)
            rows_I.append(picked.reindex(cols_I) if picked is not None else pd.Series(index=cols_I, dtype="object"))
            continue
    # ==== fin regla forzada ====

    # Regla especial por ES0174735037 (buscar por Name usando pattern_corto)
    if str(rowII.get("ISIN", "")).strip().upper() == "ES0174735037":
        if "Name" in dfI_all.columns:
            cand = dfI_all["Name"].astype(str).str.contains(pattern_corto, case=False, regex=True, na=False)
            cand = dfI_all[cand]
            if not cand.empty:
                if "VALOR ACTUAL (EUR)" in cand.columns:
                    cand = cand.sort_values("VALOR ACTUAL (EUR)", ascending=False)
                picked = cand.iloc[0]

    # Regla general por Family Name (preferir Currency/Hedged y valor)
    if picked is None:
        fam = rowII.get("Family Name")
        if pd.notna(fam) and "Family Name" in dfI_all.columns:
            cand = dfI_all[dfI_all["Family Name"] == fam].copy()
            if not cand.empty:
                if "Currency" in cand.columns and "Hedged" in cand.columns:
                    cand["_pref_cur"] = cand["Currency"].astype(str).eq(str(rowII.get("Currency",""))).astype(int)
                    cand["_pref_hed"] = cand["Hedged"].astype(str).eq(str(rowII.get("Hedged",""))).astype(int)
                    if "VALOR ACTUAL (EUR)" in cand.columns:
                        cand["_valor"] = pd.to_numeric(cand["VALOR ACTUAL (EUR)"], errors="coerce").fillna(0)
                        cand = cand.sort_values(["_pref_cur","_pref_hed","_valor"], ascending=[False, False, False])
                        cand = cand.drop(columns=["_valor"])
                    else:
                        cand = cand.sort_values(["_pref_cur","_pref_hed"], ascending=[False, False])
                    cand = cand.drop(columns=["_pref_cur","_pref_hed"])
                picked = cand.iloc[0]

    rows_I.append(picked.reindex(cols_I) if picked is not None else pd.Series(index=cols_I, dtype="object"))

